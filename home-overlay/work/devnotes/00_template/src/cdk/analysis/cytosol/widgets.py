from src.cdk.analysis.cytosol import platereader as pr
import pandas as pd

import matplotlib as mpl

import timple
import timple.timedelta

import seaborn as sns

import matplotlib.pyplot as plt
import ipywidgets as widgets
from ipywidgets import Output
from IPython.display import display

import src.cdk.logging

def interactive_curve_by_experiment(my_data, toggle_col='Experiment', display_by='Name'):

    def sns_plot_experiment(experiment):

        # plt.clf()
        plt.close()

        experiment_data = my_data[my_data[toggle_col] == experiment]

        plt.figure(figsize=(10, 6))
        for row, group in experiment_data.groupby(display_by):
            sns.lineplot(x='Seconds', y='Data', data=group, label=row)

        plt.show()

    # Create widgets for the parameters
    toggle = widgets.ToggleButtons(
        options=my_data[toggle_col].unique().tolist(),
        description=toggle_col+":",
        disabled=False,
        button_style=''
    )

    # Use interact to link the widgets to the plotting function
    my_widget = widgets.interact(sns_plot_experiment, experiment=toggle)

def interactive_ss_by_experiment(my_data, my_ss_data, toggle_col='Experiment', display_by='Name'):

    def sns_plot_experiment_bars(experiment):

        plt.close()

        combined_df = pd.merge(my_ss_data, my_data[['Well', 'Name', 'Experiment']], on='Well', how='left').drop_duplicates()
        experiment_data = combined_df[combined_df['Experiment'] == experiment]

        plt.figure(figsize=(10, 6))
        sns.catplot(data=experiment_data, kind="bar", x=display_by, y="Data_steadystate", height=5, aspect=1)
        # Rotate x-axis labels
        plt.xticks(rotation=60, ha='right', fontsize=10)
        plt.tight_layout
        plt.show()

    # Create widgets for the parameters
    toggle = widgets.ToggleButtons(
        options=my_data[toggle_col].unique().tolist(),
        description=toggle_col+":",
        disabled=False,
        button_style=''
    )

    # Use interact to link the widgets to the plotting function
    my_widget = widgets.interact(sns_plot_experiment_bars, experiment=toggle)

def interactive_curve_by_well(my_data, my_kinetics):

    def plot_kinetics_wrapper(well, annotate=True):
        plt.clf()
        well_df = my_data[my_data['Well'] == well]
        pr.plot_kinetics_by_well(well_df, my_kinetics, annotate=annotate)
        plt.show()

    # Create widgets for the parameters
    toggle = widgets.ToggleButtons(
        options=my_data['Well'].unique().tolist(),
        description='Well:',
        disabled=False,
        button_style='', # 'success', 'info', 'warning', 'danger' or ''
        tooltips=['Description of slow', 'Description of regular', 'Description of fast'],
    #     icons=['check'] * 3
    )

    # Use interact to link the widgets to the plotting function
    my_widget = widgets.interact(plot_kinetics_wrapper, well=toggle)

def interactive_kinetic_by_experiment(my_data, my_kinetics, toggle_col="Experiment"):
    
    # Create widgets for the parameters
    toggle = widgets.ToggleButtons(
        options=my_data[toggle_col].unique().tolist(),
        description=toggle_col+":",
        disabled=False,
        button_style=''
    )

    # Define the first dropdown menu (level 0)
    level_zero_dropdown = widgets.Dropdown(
        options=['Velocity', 'Lag', 'Steady State', 'Fit'],
        value='Lag',
        description='Property:',
)

    # Define the second dropdown menu (level 1)
    level_one_dropdown = widgets.Dropdown(
        options=[],  # Initially empty
        value=None,
        description='Item:',
)

    # Define a plot placeholder
    plot_output = Output()

    # Function to update the second dropdown based on the first dropdown's selection
    def update_items(change):
        if change['new'] == 'Velocity':
            level_one_dropdown.options = my_kinetics.columns[my_kinetics.columns.get_level_values(0) == 'Velocity'].get_level_values(1).tolist()
        elif change['new'] == 'Lag':
            level_one_dropdown.options = my_kinetics.columns[my_kinetics.columns.get_level_values(0) == 'Lag'].get_level_values(1).tolist()
        elif change['new'] == 'Steady State':
            level_one_dropdown.options = my_kinetics.columns[my_kinetics.columns.get_level_values(0) == 'Steady State'].get_level_values(1).tolist()
        elif change['new'] == 'Fit':
            level_one_dropdown.options = my_kinetics.columns[my_kinetics.columns.get_level_values(0) == 'Fit'].get_level_values(1).tolist()
        
        # Also reset the second dropdown value to None each time first dropdown changes
        level_one_dropdown.value = None

    # Function to update the plot based on selected dropdown values
    def update_plot(change):
        # Extract the selected level 0 and level 1 values
        experiment = toggle.value
        level_0 = level_zero_dropdown.value
        level_1 = level_one_dropdown.value
        
        if level_1 is None:
            return  # If no item is selected, do nothing
        
        # Create a new plot based on the selections
        with plot_output:

            # Clear previous output (including the figure)
            plot_output.clear_output(wait=True)  # This will clear the previous plot

            plt.close()
            
            # Plotting based on selected dropdown values
            plt.figure(figsize=(10, 6))  # You can adjust the size of the plot

            #filter kinetics by experiment

            combined_df = pd.merge(my_kinetics[level_0], my_data[['Well', 'Name', 'Experiment']], on='Well', how='left').drop_duplicates()
            filter_combined = combined_df[combined_df['Experiment'] == experiment]

            sns.catplot(data=filter_combined, kind="bar", x="Name", y=level_1, height=5, aspect=1)
            plt.suptitle(f'{level_0} - {level_1} Plot', fontsize=16)
            plt.xticks(rotation=60, ha='right', fontsize=10)
            plt.tight_layout

            plt.show()

    # Link the first dropdown to update the second dropdown options
    level_zero_dropdown.observe(update_items, names='value')

    # Link the second dropdown to the plot update function
    level_one_dropdown.observe(update_plot, names='value')

    toggle.observe(update_plot, names='value')

    # Display both dropdowns and the plot
    display(toggle, level_zero_dropdown, level_one_dropdown, plot_output)

    # Call the update_items once to initialize the second dropdown options
    update_items({'new': level_zero_dropdown.value})

def data_upload():
    # using Ipywidgets to manage file uploads

    label_1 = widgets.HTML("<b>Upload your platemap csv:</b>")
    uploader_1 = widgets.FileUpload()
    label_2 = widgets.HTML("<b>Upload your data txt:</b>")
    uploader_2 = widgets.FileUpload()

    # Place them in a row
    row = widgets.HBox([label_1, uploader_1, label_2, uploader_2])
    return row