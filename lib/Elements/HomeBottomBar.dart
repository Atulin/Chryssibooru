import 'package:material_ui/material_ui.dart';

/// The bottom search bar row: drawer button, search field, filter button.
///
/// Lives inside the Scaffold body rather than its bottomNavigationBar
/// slot, so resizeToAvoidBottomInset keeps it above the keyboard
/// natively while typing.
class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchSubmitted,
    required this.onFilterPressed,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    // BottomAppBar re-applies the status bar inset inside itself and
    // zeroes the bottom inset on devices that don't report one, so its
    // internal SafeArea is disabled entirely and the insets are handled
    // by the SafeArea below instead.
    return SafeArea(
      top: false,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: BottomAppBar(
          height: 60.0,
          padding: const EdgeInsets.fromLTRB(4.0, 10.0, 4.0, 10.0),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.menu),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  // Clear focus so opening (and later closing) the drawer
                  // does not restore focus to the search field and reopen
                  // the keyboard.
                  FocusManager.instance.primaryFocus?.unfocus();
                  Scaffold.of(context).openDrawer();
                },
              ),
              Expanded(
                child: SearchBar(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  hintText: 'Search Derpibooru',
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSearchSubmitted,
                  constraints: const BoxConstraints(minHeight: 40.0),
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 10.0),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                visualDensity: VisualDensity.compact,
                onPressed: onFilterPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
