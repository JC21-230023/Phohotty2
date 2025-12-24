
# `lib/pages/main_tab_page.dart`

`main_tab_page.dart`は、アプリケーションのメインのナビゲーションハブとして機能し、`BottomNavigationBar`を使用して複数のページを切り替えます。

## 主な機能

- **タブナビゲーション:**
  - `Scaffold`と`BottomNavigationBar`を使用して、`HomePage`と`TagLensPage`を切り替えるタブを提供します。
  - `_selectedIndex`を使用して、現在選択されているタブを追跡します。

- **ページの管理:**
  - `_pages`リストに、ナビゲーションバーの各タブに対応するページウィジェットを格納します。
  - `IndexedStack`を使用して、選択されたタブのページのみを表示し、他のページの状態を維持します。

- **UIの構築:**
  - `BottomNavigationBar`には、「Gallery」と「Tag Lens」の2つの`BottomNavigationBarItem`が含まれています。
  - `onTap`コールバックで`_onItemTapped`を呼び出し、ユーザーがタブをタップしたときに`_selectedIndex`を更新します。
