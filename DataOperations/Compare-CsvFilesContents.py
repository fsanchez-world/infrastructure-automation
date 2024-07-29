import csv
import sys

def read_csv(file_path):
    with open(file_path, mode='r', newline='') as file:
        reader = csv.DictReader(file)
        data = [row for row in reader]
    return data, reader.fieldnames

def sort_data(data, main_sort_column):
    return sorted(data, key=lambda x: x[main_sort_column])

def compare_csv_files(csv_file1, csv_file2, main_sort_column):
    # Read the CSV files
    data1, columns1 = read_csv(csv_file1)
    data2, columns2 = read_csv(csv_file2)
    
    # Ensure both files have the same columns
    if columns1 != columns2:
        print("The CSV files have different columns and cannot be compared.")
        return
    
    # Sort the data based on the main sorting column
    sorted_data1 = sort_data(data1, main_sort_column)
    sorted_data2 = sort_data(data2, main_sort_column)
    
    # Create dictionaries for quick lookup by the main_sort_column
    dict_data1 = {row[main_sort_column]: row for row in sorted_data1}
    dict_data2 = {row[main_sort_column]: row for row in sorted_data2}
    
    # Compare the sorted data
    differences = []
    matched_keys = set(dict_data1.keys()).intersection(set(dict_data2.keys()))
    
    for key in matched_keys:
        if dict_data1[key] != dict_data2[key]:
            differences.append((dict_data1[key], dict_data2[key]))
    
    if not differences:
        print("The configurations match!")
    else:
        print(f"{len(differences)} Differences found:\n")
        for i, (row1, row2) in enumerate(differences, 1):
            print(f"{i}) Protection Job:")
            print(f"- {row1}")
            print(f"+ {row2}\n")
    
    # Find missing and extra rows
    missing_in_data2 = [dict_data1[key] for key in dict_data1 if key not in dict_data2]
    extra_in_data2 = [dict_data2[key] for key in dict_data2 if key not in dict_data1]

    if missing_in_data2:
        print(f"Items with no match on {csv_file2}:")
        for row in missing_in_data2:
            print(f"- {row}")
        print()

    if extra_in_data2:
        print(f"Items with no match on {csv_file1}:")
        for row in extra_in_data2:
            print(f"- {row}")

if __name__ == "__main__":
    # Inputs from command line arguments
    if len(sys.argv) != 4:
        print("Usage: python compare_csv.py <csv_file1> <csv_file2> <main_sort_column>")
        sys.exit(1)
    
    csv_file1 = sys.argv[1]
    csv_file2 = sys.argv[2]
    main_sort_column = sys.argv[3]
    
    # Compare the CSV files
    compare_csv_files(csv_file1, csv_file2, main_sort_column)