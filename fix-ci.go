package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <path_to_directory_or_files>")
		os.Exit(1)
	}

	files := os.Args[1:]
	if len(files) == 0 {
		fmt.Println("No YAML files found matching the given pattern.")
		os.Exit(1)
	}

	// Process each YAML file
	for _, filePath := range files {
		fmt.Printf("Processing file: %s\n", filePath)
		err := updateCIFile(filePath)
		if err != nil {
			fmt.Printf("Error updating file %s: %v\n", filePath, err)
		} else {
			fmt.Printf("Successfully updated: %s\n", filePath)
		}
	}
}

func updateCIFile(filePath string) error {
	// Read the YAML file
	content, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("error reading file %s: %v", filePath, err)
	}
	lines := strings.Split(string(content), "\n")
	for i, line := range lines {
		if strings.Contains(line, "uses: docker/setup-qemu-action@v3") {
			if strings.TrimSpace(lines[i+1]) != "with:" {
				j := strings.Index(line, "uses:")
				fixes := []string{
					line[:j] + "with:",
					line[:j] + "  cache-image: false",
				}
				lines = append(lines[:i+1], append(fixes, lines[i+1:]...)...)
			}
			break
		}
	}

	// Write the updated YAML content back to the file, preserving the format
	err = os.WriteFile(filePath, []byte(strings.Join(lines, "\n")), 0644)
	if err != nil {
		return fmt.Errorf("error writing file %s: %v", filePath, err)
	}

	return nil
}
