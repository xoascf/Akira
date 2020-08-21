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

public class Akira.Layouts.Partials.GridItem : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    private Gtk.Grid fill_chooser;
    private Gtk.Button hidden_button;
    private Gtk.Button delete_button;
    private Gtk.Image hidden_button_icon;
    public Akira.Partials.InputField opacity_container;

    public Akira.Models.GridsItemModel model { get; construct; }

    private int alpha {
        owned get {
            return model.alpha;
        } set {
            model.alpha = value;
        }
    }

    private bool hidden {
        owned get {
            return model.hidden;
        } set {
            model.hidden = value;
            set_hidden_button ();
            toggle_ui_visibility ();
        }
    }

    public GridItem (Akira.Window window, Akira.Models.GridsItemModel model) {
        Object (
            window: window,
            model: model
        );
    }

    construct {
        create_ui ();

        // Update view BEFORE event bindings in order
        // to not trigger bindings on first assignment.
        update_view ();

        create_event_bindings ();
        show_all ();
    }

    private void update_view () {
        hidden = model.hidden;
    }

    private void create_ui () {
        margin_top = margin_bottom = 5;

        fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;
        fill_chooser.margin_end = 5;

        opacity_container = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_container.entry.sensitive = true;
        opacity_container.entry.value = Math.round ((double) alpha / 255 * 100);

        opacity_container.entry.bind_property (
            "value", model, "alpha",
            BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                targetval.set_int ((int) ((double) srcval / 100 * 255));
                return true;
            },
            (binding, srcval, ref targetval) => {
                targetval.set_double ((srcval.get_int () * 100) / 255);
                return true;
            });

        fill_chooser.attach (opacity_container, 2, 0, 1, 1);

        hidden_button = new Gtk.Button ();
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("button-rounded");
        hidden_button.can_focus = false;
        hidden_button.valign = Gtk.Align.CENTER;
        hidden_button.tooltip_text = _("Toggle visibility");

        delete_button = new Gtk.Button ();
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.get_style_context ().add_class ("button-rounded");
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR));
        delete_button.tooltip_text = _("Delete fill");

        attach (fill_chooser, 0, 0, 1, 1);
        attach (hidden_button, 1, 0, 1, 1);
        attach (delete_button, 2, 0, 1, 1);
    }

    private void create_event_bindings () {
        delete_button.clicked.connect (on_delete_item);
        hidden_button.clicked.connect (toggle_visibility);
        model.notify.connect (on_model_changed);
    }

    private void on_model_changed () {
        //  model.item.reset_colors ();
        //  set_button_color ();
        //  set_color_chooser_color ();
    }

    private void on_delete_item () {
        model.list_model<Akira.Models.GridsItemModel>.remove_item.begin (model);
        window.event_bus.fill_deleted ();
    }

    private void set_hidden_button () {
        if (hidden_button_icon != null) {
            hidden_button.remove (hidden_button_icon);
        }

        hidden_button_icon = new Gtk.Image.from_icon_name (
            "layer-%s-symbolic".printf (hidden ? "hidden" : "visible"),
            Gtk.IconSize.SMALL_TOOLBAR);

        hidden_button.add (hidden_button_icon);
        hidden_button_icon.show_all ();
    }

    private void toggle_visibility () {
        hidden = !hidden;
        toggle_ui_visibility ();
    }

    private void toggle_ui_visibility () {
        if (hidden) {
            get_style_context ().add_class ("disabled");
            return;
        }

        get_style_context ().remove_class ("disabled");
    }
}
