#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libfsext.h>

void print_error(libfsext_error_t *error) {
    if (error) {
        fprintf(stderr, "Error: ");
        libfsext_error_fprint(error, stderr);
        libfsext_error_free(&error);
    }
}

void enumerate_entry(libfsext_file_entry_t *entry, const char *parent_path) {
    libfsext_error_t *error = NULL;
    
    // Get name
    size_t name_size = 0;
    char *name = NULL;
    if (libfsext_file_entry_get_utf8_name_size(entry, &name_size, &error) == 1 && name_size > 0) {
        name = malloc(name_size);
        if (libfsext_file_entry_get_utf8_name(entry, (uint8_t *)name, name_size, &error) != 1) {
            libfsext_error_free(&error);
            free(name);
            name = strdup("unknown_name");
        }
    } else {
        libfsext_error_free(&error);
        name = strdup(""); // Root directory has no name
    }
    
    // Get metadata
    uint32_t inode = 0;
    libfsext_file_entry_get_inode_number(entry, &inode, NULL);
    
    uint16_t mode = 0;
    libfsext_file_entry_get_file_mode(entry, &mode, NULL);
    
    uint64_t size = 0;
    libfsext_file_entry_get_size(entry, &size, NULL);
    
    uint32_t uid = 0, gid = 0;
    libfsext_file_entry_get_owner_identifier(entry, &uid, NULL);
    libfsext_file_entry_get_group_identifier(entry, &gid, NULL);
    
    int64_t ctime = 0, mtime = 0, atime = 0;
    libfsext_file_entry_get_creation_time(entry, &ctime, NULL);
    libfsext_file_entry_get_modification_time(entry, &mtime, NULL);
    libfsext_file_entry_get_access_time(entry, &atime, NULL);
    
    // Type classification (simplified)
    const char *type = "unknown";
    if ((mode & 0xF000) == 0x4000) type = "dir";
    else if ((mode & 0xF000) == 0x8000) type = "file";
    else if ((mode & 0xF000) == 0xA000) type = "symlink";
    
    printf("ENTRY: path='%s/%s', type=%s, inode=%u, size=%llu, mode=%04o, uid=%u, gid=%u\n",
           parent_path, name, type, inode, (unsigned long long)size, mode, uid, gid);
           
    if (strcmp(type, "symlink") == 0) {
        size_t link_size = 0;
        if (libfsext_file_entry_get_utf8_symbolic_link_target_size(entry, &link_size, NULL) == 1 && link_size > 0) {
            char *link_target = malloc(link_size);
            if (libfsext_file_entry_get_utf8_symbolic_link_target(entry, (uint8_t *)link_target, link_size, NULL) == 1) {
                printf("  -> SYMLINK TARGET: '%s'\n", link_target);
            }
            free(link_target);
        }
    }
    
    if (strcmp(type, "dir") == 0 && strcmp(name, ".") != 0 && strcmp(name, "..") != 0) {
        int num_sub_entries = 0;
        if (libfsext_file_entry_get_number_of_sub_file_entries(entry, &num_sub_entries, &error) == 1) {
            char new_path[1024];
            snprintf(new_path, sizeof(new_path), "%s/%s", parent_path, name);
            for (int i = 0; i < num_sub_entries; i++) {
                libfsext_file_entry_t *sub_entry = NULL;
                if (libfsext_file_entry_get_sub_file_entry_by_index(entry, i, &sub_entry, &error) == 1) {
                    enumerate_entry(sub_entry, new_path);
                    libfsext_file_entry_free(&sub_entry, NULL);
                } else {
                    printf("  [Error getting sub entry %d]\n", i);
                    libfsext_error_free(&error);
                }
            }
        } else {
            printf("  [Error getting number of sub entries]\n");
            libfsext_error_free(&error);
        }
    }
    
    free(name);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <image_file> [offset]\n", argv[0]);
        return 1;
    }
    
    const char *filename = argv[1];
    off64_t offset = 0;
    if (argc >= 3) {
        offset = strtoll(argv[2], NULL, 10);
    }
    
    libfsext_error_t *error = NULL;
    
    libfsext_volume_t *volume = NULL;
    if (libfsext_volume_initialize(&volume, &error) != 1) {
        fprintf(stderr, "Failed to initialize volume.\n");
        print_error(error);
        return 1;
    }
    
    if (libfsext_volume_open(volume, filename, LIBFSEXT_OPEN_READ, &error) != 1) {
        fprintf(stderr, "Failed to open volume.\n");
        print_error(error);
        libfsext_volume_free(&volume, NULL);
        return 1;
    }
    
    printf("Successfully opened volume: %s\n", filename);
    
    uint16_t format_version = 0;
    if (libfsext_volume_get_format_version(volume, &format_version, NULL) == 1) {
        printf("Filesystem format version: %u\n", format_version); // e.g. 2, 3, 4
    }
    
    libfsext_file_entry_t *root_entry = NULL;
    if (libfsext_volume_get_root_directory(volume, &root_entry, &error) != 1) {
        fprintf(stderr, "Failed to get root directory.\n");
        print_error(error);
    } else {
        enumerate_entry(root_entry, "");
        libfsext_file_entry_free(&root_entry, NULL);
    }
    
    libfsext_volume_close(volume, &error);
    libfsext_volume_free(&volume, &error);
    
    return 0;
}
