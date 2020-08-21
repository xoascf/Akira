/*
 * Copyright (c) 2020 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

 public class Akira.Layouts.Partials.GridsPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public Gtk.Button add_btn;
    public Gtk.ListBox grids_list_container;
    public Akira.Models.ListModel<Akira.Models.GridsItemModel> list_model;
    public Gtk.Grid title_cont;
    private Lib.Models.CanvasItem selected_item;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public GridsPanel (Akira.Window window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.HORIZONTAL
        );
    }

    construct {
        title_cont = new Gtk.Grid ();
        title_cont.orientation = Gtk.Orientation.HORIZONTAL;
        title_cont.hexpand = true;
        title_cont.get_style_context ().add_class ("option-panel");

        var label = new Gtk.Label (_("Grids"));
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        add_btn = new Gtk.Button ();
        add_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_btn.can_focus = false;
        add_btn.valign = Gtk.Align.CENTER;
        add_btn.halign = Gtk.Align.CENTER;
        add_btn.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_btn, 1, 0, 1, 1);

        list_model = new Akira.Models.ListModel<Akira.Models.GridsItemModel> ();

        grids_list_container = new Gtk.ListBox ();
        grids_list_container.margin_top = 5;
        grids_list_container.margin_bottom = 15;
        grids_list_container.margin_start = 10;
        grids_list_container.margin_end = 5;
        grids_list_container.selection_mode = Gtk.SelectionMode.NONE;
        grids_list_container.get_style_context ().add_class ("fills-list");

        grids_list_container.bind_model (list_model, item => {
            return new Akira.Layouts.Partials.GridItem (window, (Akira.Models.GridsItemModel) item);
        });

        attach (title_cont, 0, 0, 1, 1);
        attach (grids_list_container, 0, 1, 1, 1);
        show_all ();

        create_event_bindings ();
    }

    private void create_event_bindings () {
        toggled = false;
        window.event_bus.selected_items_changed.connect (on_selected_items_changed);

        //  window.event_bus.fill_deleted.connect (() => {
        //      add_btn.show ();
        //      window.main_window.left_sidebar.queue_resize ();
        //  });

        add_btn.clicked.connect (() => {
            var model_item = create_model ();
            list_model.add_item.begin (model_item);
            window.main_window.left_sidebar.queue_resize ();
        });

        //  // Listen to the model changes when adding/removing items.
        //  list_model.items_changed.connect ((position, removed, added) => {
        //      if (selected_item != null) {
        //          // If an item is still selected, update the has_fill property
        //          // to TRUE or FALSE based on the model changes.

        //          // This will need to be updated in the future once we're dealing
        //          // with multiple fill colors, updating to FALSE only if all
        //          // the fills have been deleted.
        //          selected_item.has_fill = (added == 1);
        //      }
        //  });
    }

    private void on_selected_items_changed (List<Lib.Models.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            selected_item = null;
            list_model.clear.begin ();
            toggled = false;
            return;
        }

        if (selected_item == null || selected_item != selected_items.nth_data (0)) {
            toggled = true;
            selected_item = selected_items.nth_data (0);

            if (!(selected_item is Lib.Models.CanvasArtboard)) {
                toggled = false;
                return;
            }

            var model_item = create_model ();
            list_model.add_item.begin (model_item);
        }
    }

    private Akira.Models.GridsItemModel create_model () {
        return new Akira.Models.GridsItemModel (selected_item, list_model);
    }
}
