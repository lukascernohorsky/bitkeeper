#!/usr/bin/env tclsh
# Tcl translation of listbox.l using ttk::treeview

namespace eval ::ListBoxState {
    variable data
}

proc ListBox_init {pathName args} {
    namespace eval ::ListBoxState {}
    variable ::ListBoxState::data

    array set opts {-redraw 1 -state normal}
    if {[llength $args]} {
        array set opts $args
    }

    set self $pathName
    set data($self,rowCount) 0
    set data($self,itemList) {}
    set data($self,state) $opts(-state)
    set data($self,redraw) [expr {$opts(-redraw) ? 1 : 0}]
    set data($self,selected) ""

    set w_table ${self}.table
    set w_vscroll ${self}.vscroll
    set w_hscroll ${self}.hscroll

    ttk::frame $self
    ttk::treeview $w_table \
        -show tree \
        -columns {text} \
        -selectmode browse \
        -yscrollcommand [list $w_vscroll set] \
        -xscrollcommand [list $w_hscroll set]
    $w_table column #0 -anchor w -stretch 1 -minwidth 40

    ttk::scrollbar $w_vscroll -orient vertical -command [list $w_table yview]
    ttk::scrollbar $w_hscroll -orient horizontal -command [list $w_table xview]

    grid $w_table -row 0 -column 0 -sticky nesw
    grid $w_vscroll -row 0 -column 1 -sticky ns
    grid $w_hscroll -row 1 -column 0 -sticky ew
    grid rowconfigure $self 0 -weight 1
    grid columnconfigure $self 0 -weight 1

    bind $w_table <<TreeviewSelect>> [list ListBox::_handleSelect $self %W]
    bind $w_table <ButtonRelease-1> [list ListBox::_handleClick $self %W %x %y]

    set data($self,w_path) $self
    set data($self,w_table) $w_table
    set data($self,w_vscroll) $w_vscroll
    set data($self,w_hscroll) $w_hscroll

    return $self
}

proc ListBox_bind {self args} {
    variable ::ListBoxState::data
    set w_table $data($self,w_table)
    return [eval [linsert $args 0 bind $w_table]]
}

proc ListBox_cget {self option} {
    variable ::ListBoxState::data
    switch -- $option {
        -redraw {return $data($self,redraw)}
        -state {return $data($self,state)}
        default {return ""}
    }
}

proc ListBox_configure {self args} {
    variable ::ListBoxState::data
    foreach {option value} $args {
        switch -- $option {
            -redraw {set data($self,redraw) [expr {$value ? 1 : 0}]}
            -state {set data($self,state) $value}
            default {
                set w_table $data($self,w_table)
                catch {$w_table configure $option $value}
            }
        }
    }
}

proc ListBox_grid {self args} {
    set w_path $self
    if {[string match -* [lindex $args 0]]} {
        return [eval [linsert $args 0 grid $w_path]]
    }
    set parent [lindex $args 0]
    set rest [lrange $args 1 end]
    return [eval [linsert $rest 0 grid $parent $w_path]]
}

proc ListBox_itemDelete {self args} {
    variable ::ListBoxState::data
    set w_table $data($self,w_table)
    set low [llength $data($self,itemList)]
    foreach itemName $args {
        set idx [ListBox_index $self $itemName]
        if {$idx < 0} continue
        if {$idx < $low} {set low $idx}
        set data($self,itemList) [lreplace $data($self,itemList) $idx $idx]
        catch {$w_table delete $itemName}
        foreach key {text image bg fg font data redraw} {
            catch {unset data($self,item,$itemName,$key)}
        }
    }
    ListBox_redraw $self
}

proc ListBox_exists {self itemName} {
    variable ::ListBoxState::data
    return [info exists data($self,item,$itemName,text)]
}

proc ListBox_index {self itemName} {
    variable ::ListBoxState::data
    set idx [lsearch -exact $data($self,itemList) $itemName]
    return $idx
}

proc ListBox_itemInsert {self idx args} {
    variable ::ListBoxState::data
    set w_table $data($self,w_table)
    array set opts {-background "" -foreground "" -text "" -data "" -image "" -id "" -font ""}
    if {[llength $args]} {
        array set opts $args
    }
    incr data($self,rowCount)
    set id $opts(-id)
    if {$id eq ""} {set id "item$data($self,rowCount)"}

    if {$idx eq "end"} {
        lappend data($self,itemList) $id
        set where end
    } else {
        set data($self,itemList) [linsert $data($self,itemList) $idx $id]
        set where $idx
    }

    foreach key {text image bg fg font data} {
        set data($self,item,$id,$key) $opts(-[string trimleft $key])
    }

    set tags [ListBox::_applyTags $self $id]
    $w_table insert {} $where -iid $id -text $data($self,item,$id,text) -image $data($self,item,$id,image) -tags $tags

    return $id
}

proc ListBox_item {self index} {
    variable ::ListBoxState::data
    if {$index eq "end"} {
        set idx [expr {[llength $data($self,itemList)] - 1}]
    } else {
        set idx $index
    }
    if {$idx < 0 || $idx >= [llength $data($self,itemList)]} {
        return ""
    }
    return [lindex $data($self,itemList) $idx]
}

proc ListBox_itemcget {self itemName option} {
    variable ::ListBoxState::data
    if {![ListBox_exists $self $itemName]} {return ""}
    switch -- $option {
        -data {return $data($self,item,$itemName,data)}
        -text {return $data($self,item,$itemName,text)}
        -image {return $data($self,item,$itemName,image)}
        default {return ""}
    }
}

proc ListBox_itemconfigure {self itemName args} {
    variable ::ListBoxState::data
    if {![ListBox_exists $self $itemName]} {return ""}
    foreach {option value} $args {
        switch -- $option {
            -data {set data($self,item,$itemName,data) $value}
            -text {set data($self,item,$itemName,text) $value}
            -image {set data($self,item,$itemName,image) $value}
            -font {set data($self,item,$itemName,font) $value}
            -background {set data($self,item,$itemName,bg) $value}
            -foreground {set data($self,item,$itemName,fg) $value}
            default {}
        }
    }
    ListBox::_updateItem $self $itemName
    return [lindex $args end]
}

proc ListBox_items {self} {
    variable ::ListBoxState::data
    return $data($self,itemList)
}

proc ListBox_pack {self args} {
    if {[string match -* [lindex $args 0]]} {
        return [eval [linsert $args 0 pack $self]]
    }
    set parent [lindex $args 0]
    set rest [lrange $args 1 end]
    return [eval [linsert $rest 0 pack $parent $self]]
}

proc ListBox_redraw {self} {
    # Treeview redraws automatically; nothing explicit needed.
    return
}

proc ListBox_see {self itemName} {
    variable ::ListBoxState::data
    if {![ListBox_exists $self $itemName]} {return ""}
    $data($self,w_table) see $itemName
    return $itemName
}

proc ListBox_select {self itemName} {
    variable ::ListBoxState::data
    if {![ListBox_exists $self $itemName]} {return}
    set data($self,selected) $itemName
    set w_table $data($self,w_table)
    $w_table selection set $itemName
    ListBox_see $self $itemName
}

proc ListBox_selectionClear {self} {
    variable ::ListBoxState::data
    set w_table $data($self,w_table)
    $w_table selection remove [$w_table selection]
    set data($self,selected) ""
}

proc ListBox_selectionGet {self} {
    variable ::ListBoxState::data
    return $data($self,selected)
}

proc ListBox_selectionSet {self first last} {
    variable ::ListBoxState::data
    set items {}
    for {set i $first} {$i <= $last} {incr i} {
        set itm [ListBox_item $self $i]
        if {$itm ne ""} {lappend items $itm}
    }
    if {[llength $items]} {
        $data($self,w_table) selection set $items
        set data($self,selected) [lindex $items 0]
    }
}

proc ListBox_Click {self x y} {
    # Compatibility stub; events are generated by _handleClick.
    ListBox::_handleClick $self $::ListBoxState::data($self,w_table) $x $y
}

proc ListBox_GetText {self row col} {
    # Compatibility stub returning text for row
    set item [ListBox_item $self $row]
    if {$item eq ""} {return ""}
    return [ListBox_itemcget $self $item -text]
}

proc ListBox_RedrawRows {first} {
    # No-op in Tcl implementation
    return
}

proc ListBox_GetCell {row option} {
    switch -- $option {
        -image {return "$row,0"}
        -text {return "$row,1"}
    }
    return ""
}

proc ListBox_ImageTag {i} {return ""}
proc ListBox_GetRowTag {i} {return ""}
proc ListBox_Redraw {} {return}

proc ListBox::_applyTags {self itemName} {
    variable ::ListBoxState::data
    set tags {}
    set bg $data($self,item,$itemName,bg)
    set fg $data($self,item,$itemName,fg)
    set font $data($self,item,$itemName,font)
    if {$bg ne "" || $fg ne "" || $font ne ""} {
        set tag "lb-[string map {:: _} $self]-$bg-$fg-$font"
        set w_table $data($self,w_table)
        if {[lsearch -exact [$w_table tag names] $tag] < 0} {
            $w_table tag configure $tag -background $bg -foreground $fg -font $font
        }
        lappend tags $tag
    }
    return $tags
}

proc ListBox::_updateItem {self itemName} {
    variable ::ListBoxState::data
    set w_table $data($self,w_table)
    set tags [ListBox::_applyTags $self $itemName]
    $w_table item $itemName -text $data($self,item,$itemName,text) \
        -image $data($self,item,$itemName,image) -tags $tags
}

proc ListBox::_handleSelect {self widget} {
    variable ::ListBoxState::data
    if {$data($self,state) eq "disabled"} {
        return
    }
    set sel [$widget selection]
    if {[llength $sel]} {
        set item [lindex $sel 0]
        set data($self,selected) $item
        event generate $widget <<SelectItem>> -data $item
    }
}

proc ListBox::_handleClick {self widget x y} {
    variable ::ListBoxState::data
    if {$data($self,state) eq "disabled"} {
        return
    }
    set row [$widget identify row $y]
    if {$row eq ""} {return}
    set data($self,selected) $row
    set element [$widget identify element $x $y]
    if {$element eq "image"} {
        event generate $widget <<ClickIcon>> -data $row
    } else {
        event generate $widget <<SelectItem>> -data $row
    }
}
