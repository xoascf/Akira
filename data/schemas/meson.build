gschema_file_conf = configuration_data()
gschema_file_conf.set('SCHEMA_ID', application_id)
gschema_file_conf.set('SCHEMA_PATH', schema_path)
gschema_file_conf.set('GETTEXT_PACKAGE', gettext_package)

gschema_file = i18n.merge_file(
    input: configure_file(
        input: meson.project_name() + '.gschema.xml.in.in',
        output: '@BASENAME@',
        configuration: gschema_file_conf
    ),
    output: application_id + '.gschema.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(akira_datadir, 'glib-2.0', 'schemas')
)
