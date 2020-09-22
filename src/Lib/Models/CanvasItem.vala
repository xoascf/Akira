/*
 * Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public enum Akira.Lib.Models.CanvasItemType {
    RECT,
    ELLIPSE,
    TEXT,
    IMAGE,
    ARTBOARD
}

public interface Akira.Lib.Models.CanvasItem : Goo.CanvasItemSimple, Goo.CanvasItem {
    // Identifiers.
    public abstract Models.CanvasItemType item_type { get; set; }
    public abstract string id { get; set; }
    public abstract string name { get; set; }

    // Transform Panel attributes.
    public abstract double opacity { get; set; }
    public abstract double rotation { get; set; }

    // Fill Panel attributes.
    // If FALSE, don't add a FillItem to the ListModel
    public abstract bool has_fill { get; set; default = true; }
    public abstract int fill_alpha { get; set; }
    public abstract Gdk.RGBA color { get; set; }
    public abstract string color_string { get; set; }
    public abstract bool hidden_fill { get; set; default = false; }

    // Border Panel attributes.
    // If FALSE, don't add a BorderItem to the ListModel
    public abstract bool has_border { get; set; default = true; }
    public abstract int border_size { get; set; }
    public abstract Gdk.RGBA border_color { get; set; }
    public abstract string border_color_string { get; set; }
    public abstract int stroke_alpha { get; set; }
    public abstract bool hidden_border { get; set; default = false; }

    // Style Panel attributes.
    public abstract bool size_locked { get; set; default = false; }
    public abstract double size_ratio { get; set; default = 1.0; }
    public abstract bool flipped_h { get; set; default = false; }
    public abstract bool flipped_v { get; set; default = false; }
    public abstract bool show_border_radius_panel { get; set; default = false; }
    public abstract bool show_fill_panel { get; set; default = false; }
    public abstract bool show_border_panel { get; set; default = false; }

    // Layers panel attributes.
    public abstract bool selected { get; set; }
    public abstract bool locked { get; set; default = false; }
    public abstract string layer_icon { get; set; }
    public abstract int z_index { get; set; }

    public abstract Akira.Lib.Canvas canvas { get; set; }
    public abstract Models.CanvasArtboard? artboard { get; set; }
    public abstract Managers.GhostBoundsManager bounds_manager { get; set; }

    public abstract double relative_x { get; set; }
    public abstract double relative_y { get; set; }

    // Knows if an item was created or loaded for ordering purpose.
    public abstract bool loaded { get; set; default = false; }

    public double get_coords (string coord_id) {
        double _coord = 0.0;

        get (coord_id, out _coord);

        return _coord;
    }

    public void delete () {
        if (artboard != null) {
            artboard.remove_item (this);
            return;
        }

        remove ();
    }

    public static string create_item_id (Models.CanvasItem item, string item_name) {
        // Make sure the initial ID is the current count of the total amount
        // of items with the same item type in the same artboard.
        int count = 0;
        var items = item.artboard != null ? item.artboard.items : item.canvas.window.items_manager.free_items;
        if (item is Models.CanvasArtboard) {
            items = item.canvas.window.items_manager.artboards;
        }

        foreach (var _item in items) {
            if (_item.item_type == item.item_type) {
                count++;
            }
        }

        return item_name.printf (count);
    }

    public static void init_item (Goo.CanvasItem item) {
        item.set ("opacity", 100.0);
        item.set ("fill-alpha", 255);
        item.set ("stroke-alpha", 255);

        var canvas_item = item as Models.CanvasItem;
        canvas_item.size_ratio = 1.0;

        // Populate the name with the item's id
        // to show it when added to the LayersPanel
        canvas_item.name = canvas_item.id;
    }

    public virtual void connect_to_artboard () {
        notify.connect (on_item_notify);
    }

    public virtual void disconnect_from_artboard () {
        notify.disconnect (on_item_notify);
    }

    private void on_item_notify () {
        artboard.changed (true);
    }

    public virtual void init_position (double _x, double _y) {
        if (artboard != null) {
            // Add item to the parent Artboard.
            artboard.add_child (this, -1);

            // Convert the coordinates for the artboard space.
            canvas.convert_to_item_space (artboard, ref _x, ref _y);

            relative_x = _x;
            relative_y = _y;
            return;
        }

        // Add the item to the base Canvas.
        parent.add_child (this, -1);

        // Always reset the translation matrix when positioning an item
        // in the "free canvas" space. This is to avoid previous coordinate
        // space translations to be applied twice.
        var transform = Cairo.Matrix.identity ();

        // Keep the item always in the origin and move the entire coordinate
        // system every time.
        transform.translate (_x, _y);

        // We only need to take into account the rotation relative
        // to the center of the item.
        var center_x = get_coords ("width") / 2;
        var center_y = get_coords ("height") / 2;

        transform.translate (center_x, center_y);
        transform.rotate (Utils.AffineTransform.deg_to_rad (rotation));
        transform.translate (-center_x, -center_y);

        set_transform (transform);
    }

    public virtual void position_item (double _x, double _y) {
        if (artboard != null) {
            // Add item to the parent Artboard.
            artboard.add_child (this, -1);

            // Convert the coordinates for the artboard space.
            canvas.convert_to_item_space (artboard, ref _x, ref _y);

            relative_x = _x;
            relative_y = _y;
            return;
        }

        // Add the item to the base Canvas.
        parent.add_child (this, -1);

        // Reset the relative coordinates in case the item came from an artboard.
        relative_x = 0;
        relative_y = 0;
    }

    public virtual void move (double x, double y) {
        if (artboard != null) {
            relative_x += x;
            relative_y += y;
            return;
        }

        translate (x, y);
        bounds_manager.update ();
    }

    public virtual Cairo.Matrix get_real_transform () {
        Cairo.Matrix transform = Cairo.Matrix.identity ();

        if (artboard == null) {
            get_transform (out transform);
        } else {
            artboard.get_transform (out transform);
            transform = compute_transform (transform);
        }

        return transform;
    }

    /*
     * Compute the Matrix transform of an item inside an Artboard.
     */
    public virtual Cairo.Matrix compute_transform (Cairo.Matrix transform) {
        transform.translate (relative_x, relative_y);

        var center_x = get_coords ("width") / 2;
        var center_y = get_coords ("height") / 2;
        var radians = Utils.AffineTransform.deg_to_rad (rotation);

        // Rotate around the center by the rotation amount.
        transform.translate (center_x, center_y);
        transform.rotate (radians);
        transform.translate (-center_x, -center_y);

        // Account for mirrored items.
        if (flipped_h || flipped_v) {
            var sx = flipped_h ? -1 : 1;
            var sy = flipped_v ? -1 : 1;
            transform.translate (center_x, center_y);
            transform.rotate (-radians);
            transform.scale (sx, sy);
            transform.rotate (radians);
            transform.translate (-center_x, -center_y);
        }

        return transform;
    }

    public virtual void reset_colors () {
        reset_fill ();
        reset_border ();
    }

    private void reset_fill () {
        if (hidden_fill || !has_fill) {
            set ("fill-color-rgba", null);
            color_string = "";
            return;
        }

        var rgba_fill = Gdk.RGBA ();
        rgba_fill = color;
        rgba_fill.alpha = ((double) fill_alpha) / 255 * opacity / 100;
        color_string = Utils.Color.rgba_to_hex (rgba_fill.to_string ());

        uint fill_color_rgba = Utils.Color.rgba_to_uint (rgba_fill);
        set ("fill-color-rgba", fill_color_rgba);
    }

    private void reset_border () {
        // Set a default border color in case no border is used
        // to avoid half pixel transparency during export.
        if (hidden_border || !has_border) {
            set ("stroke-color-rgba", fill_color_rgba);
            set ("line-width", 0.0);
            border_color_string = "";
            return;
        }

        var rgba_stroke = Gdk.RGBA ();
        rgba_stroke = border_color;
        rgba_stroke.alpha = ((double) stroke_alpha) / 255 * opacity / 100;
        border_color_string = Utils.Color.rgba_to_hex (rgba_stroke.to_string ());

        uint stroke_color_rgba = Utils.Color.rgba_to_uint (rgba_stroke);
        set ("stroke-color-rgba", stroke_color_rgba);
        set ("line-width", (double) border_size);
    }

    public void load_colors () {
        load_fill ();
        load_border ();
        reset_colors ();
    }

    private void load_fill () {
        if (hidden_fill || !has_fill) {
            set ("fill-color-rgba", null);
            color_string = "";
            return;
        }

        var rgba_fill = Gdk.RGBA ();
        rgba_fill.parse (color_string);
        rgba_fill.alpha = ((double) fill_alpha) / 255 * opacity / 100;
        color = rgba_fill;
    }

    private void load_border () {
        if (hidden_border || !has_border) {
            set ("stroke-color-rgba", fill_color_rgba);
            set ("line-width", 0.0);
            border_color_string = "";
            return;
        }

        var rgba_stroke = Gdk.RGBA ();
        rgba_stroke.parse (border_color_string);
        rgba_stroke.alpha = ((double) stroke_alpha) / 255 * opacity / 100;
        border_color = rgba_stroke;
    }

    /*
     * TODO: This method needs to account for the actual path of the item and not
     * just the bounding box. I don't know if this is possible directly with goocanvas
     * or it needs some cairo trickery to make it work.
     */
    public bool simple_is_item_at (double x, double y, Cairo.Context cr, bool is_pointer_event) {
        return x >= bounds_manager.x1
            && x <= bounds_manager.x2
            && y >= bounds_manager.y1
            && y <= bounds_manager.y2;
    }

    // Update the size ratio to respect the updated size.
    public void update_size_ratio () {
        size_ratio = get_coords ("width") / get_coords ("height");
    }
}
