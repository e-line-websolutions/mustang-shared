<cfoutput>
  <div class="fuelux">
      <div class="btn-group btn-group-xs" role="group">
        <button type="button" class="btn btn-info expand-all">#i18n.translate( 'expand-all' )#</button>
        <button type="button" class="btn btn-info collapse-all">#i18n.translate( 'collapse-all' )#</button>
      </div>

      <div class="btn-group btn-group-xs" role="group">
        <button type="button" class="btn btn-primary add-toplevel-group">#i18n.translate( 'add-toplevel-group' )#</button>
      </div>

    <ul class="tree" role="tree" id="hierarchy">
      <li class="tree-branch hide" data-template="treebranch" role="treeitem" aria-expanded="false">
        <div class="tree-branch-header">
          <button class="tree-branch-name">
            <i class="icon-caret  glyphicon glyphicon-play          fa fa-caret-right"></i>
            <i class="icon-folder glyphicon glyphicon-folder-close  fa fa-folder"></i>
            <span class="tree-label"></span>
          </button>
          <span class="actions pull-right">
            <i class="hierarchy-edit fa fa-pencil"></i>
            <i class="hierarchy-add fa fa-plus"></i>
          </span>
        </div>
        <ul class="tree-branch-children" role="group"></ul>
        <div class="tree-loader" role="alert">#i18n.translate( 'loading' )#</div>
      </li>
      <li class="tree-item hide" data-template="treeitem" role="treeitem">
        <button class="tree-item-name">
          <span class="icon-item fueluxicon-bullet"></span>
          <span class="tree-label"></span>
        </button>
      </li>
    </ul>
  </div>
</cfoutput>