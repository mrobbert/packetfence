
function submitFormHideModal(modal,form) {
    $.ajax({
        'async' : false,
        'url'   : form.attr('action'),
        'type'  : form.attr('method') || "POST",
        'data'  : form.serialize()
        })
        .always(function()  {
            modal.modal('hide');
        })
        .done(function(data) {
            $(window).hashchange();
        })
        .fail(function(jqXHR) {
            $("body,html").animate({scrollTop:0}, 'fast');
            var status_msg = getStatusMsg(jqXHR);
            showError($('#section h2'), status_msg);
        });
}

function initVariableList(editor) {
    $('#variable_list').on('click', '.insert-into-file', function(event) {
        var that = $(this);
        var content = that.attr("data-content");
        editor.insert(content);
        editor.focus();
        return false;
    });
}

function initShowLinesCheckBox(editor) {
    var file_editor_show_lines =  $("#file-editor-show-lines");
    var renderer = editor.renderer;
    file_editor_show_lines.off('click');
    file_editor_show_lines.click(function (e) {
        renderer.setShowGutter(this.checked);
        return true;
    });

    renderer.setShowGutter(file_editor_show_lines.is(':checked'));
}

function initSaveModal(editor,file_content) {
    var save_modal = $("#saveFile");
    var save_button = save_modal.find('a.btn-primary').first();
    save_button.off('click');

    save_button.click(function(event) {
        var form     = $('#file_editor_form');
        file_content.val(editor.getValue());
        submitFormHideModal(save_modal,form);
    });
}

function initCancelModal() {
    $('#cancelEdit').find('a.btn-primary').first().click(function(event) {
        window.location = $(this).attr('href');
    });

}

function initEditor(editor,file_content) {
    var cancel_link = $("#cancel-link");
    var file_editor_buttons = $('.form-actions a.btn');
    var enableButtonsOnChangeOnce = function(e) {
        cancel_link.attr('data-toggle','modal');
        file_editor_buttons.removeClass('disabled');
        editor.removeEventListener("change",enableButtonsOnChangeOnce);
    };

    editor.setTheme("ace/theme/monokai");
    editor.getSession().setMode("ace/mode/html");
    editor.on("change",enableButtonsOnChangeOnce);
    editor.focus();


    $('#resetContent').find('a.btn-primary').first().click(function(event) {
        editor.setValue(file_content.val(),-1);
        cancel_link.removeAttr('data-modal');
        file_editor_buttons.addClass('disabled');
        editor.on("change",enableButtonsOnChangeOnce);
    });
}

function initRenameForm(element) {
    var file_name_span = $('#file_name');
    var input_span = file_name_span.next().first();
    var width_span = input_span.next().first();
    var input = input_span.children().first();
    var rename_form = $('#rename_file');
    element.on('dblclick','#file_name',function(event){
        width_span.html(input.val());
        input.width(width_span.width() + 3);
        input_span.removeClass('hidden');
        file_name_span.addClass('hidden');
        input.focus();
    });
    $('#new_file_name').keyup(function(event){
        var input = $(this);
        if (event.keyCode == 27) {
            input.focusout();
        } else {
            width_span.html(input.val());
            input.width(width_span.width() + 3);
        }
    });
    $('#new_file_name').focusout(function(event){
        width_span.html(input.val());
        input.width(width_span.width() + 2);
        input_span.addClass('hidden');
        file_name_span.removeClass('hidden');
        rename_form[0].reset();
    });
}

function initPreviewFile(element) {
    var previewFile = $('#previewFile');
    previewFile.on('hidden',function() {
        $(this).data('modal').$element.removeData();
    });
    previewFile.on('shown',function() {
        var that = $(this);
        var modal_body = that.find('.modal-body');
        modal_body.on('ready',function(){
/*
            alert(modal_body.innerHtml);
            var iframe = modal_body.find('iframe');
            var doc =  iframe[0].contentDocument;
            var html = doc.find("html");
            var scrollWidth = html[0].scrollWidth;
            var scrollHeight = html[0].scrollHeight;
            previewFile.width((scrollWidth + 40 ) + "px");
            previewFile.height((scrollHeight + 60 ) + "px");
            modal_body.width((scrollWidth + 40 ) + "px");
            modal_body.height((scrollHeight + 60 ) + "px");
            iframe.width((scrollWidth + 40 ) + "px");
            iframe.height((scrollHeight + 60 ) + "px");
*/
        });
    });
}

function initEditorPage(element) {
    var file_content = $('#file_content');
    var editor = ace.edit("editor");
    initVariableList(editor);
    initShowLinesCheckBox(editor);
    initSaveModal(editor,file_content);
    initCancelModal();
    initEditor(editor,file_content);
    initRenameForm(element);
    initPreviewFile(element);
}

function initCollapse(element) {
    element.on('show hidden','.collapse',function(event) {
        console.log(this);
        console.log(event);
        var that = $(this);
        console.log(that);
        var tr = that.closest('tr').first();
        console.log(tr);
        tr.swap_class('toggle');
        var link = element.find('[data-target="#' + that.attr('id') + '"]');
        link.find('[data-swap]').swap_class('toggle');
        event.stopPropagation();//To stop the event from closing parents
    });
}

function initCopyModal(element) {
    var modal = $('#copyModal');
    var button = modal.find('.btn-primary').first();
    modal.on('hidden',function() {
        $(this).data('modal').$element.removeData();
    });
    button.off("click");
    button.click(function(event) {
        var form = modal.find("#copyModalForm");
        submitFormHideModal(modal,form);
    });

    element.on('submit',"#copyModalForm",function () {
        submitFormHideModal(modal,$(this));
        return false;
    });
}

function submitFormHideModalGoToLocation(modal,form) {
    $.ajax({
        'async' : false,
        'url'   : form.attr('action'),
        'type'  : form.attr('method') || "POST",
        'data'  : form.serialize()
        })
        .always(function()  {
            modal.modal('hide');
        })
        .done(function(data, textStatus, jqXHR) {
            location.hash = jqXHR.getResponseHeader('Location');
        })
        .fail(function(jqXHR) {
            $("body,html").animate({scrollTop:0}, 'fast');
            var status_msg = getStatusMsg(jqXHR);
            showError($('#section h2'), status_msg);
        });
}

function initNewFileModal(element) {
    var modal = $('#newFileModal');
    var button = modal.find('.btn-primary').first();
    modal.on('hidden',function() {
        $(this).data('modal').$element.removeData();
    });
    button.off("click");
    button.click(function(event) {
        var form = modal.find("#newFileModalForm");
        submitFormHideModalGoToLocation(modal,form);
    });
    element.on('submit',"#newFileModalForm",function () {
        submitFormHideModalGoToLocation(modal,$(this));
        return false;
    });
}

function disabledLinks(element) {
    element.on('click','.disabled',function() { return false;});
}

function initIndexPage(element) {
}

function initCreatePage(element) {
    var modal = $('#saveProfile');
    var button = modal.find('.btn-primary').first();
    button.off("click");
    button.click(function(event) {
        var form = element.find("#create_profile");
        submitFormHideModalGoToLocation(modal,form);
    });
}

function initTemplatesPage(element) {
    initCopyModal(element);
    initCollapse(element);
    initNewFileModal(element);
}

function portalProfileGlobalInit(element) {
    disabledLinks(element);
}

$('#section').on('section.loaded',function(event) {
    var initializers = [
        {id : "#portal_profile_file_editor", initializer: initEditorPage},
        {id : "#portal_profile_files", initializer: initTemplatesPage },
        {id : "#portal_profile_index", initializer: initIndexPage },
        {id : "#portal_profile_create", initializer: initCreatePage }
    ];
    for (var i = 0; i < initializers.length; i++) {
        var initializer = initializers[i];
        var element = $(initializer.id);
        if (element.length > 0) {
            portalProfileGlobalInit(element);
            initializer.initializer(element);
        }
    }

});