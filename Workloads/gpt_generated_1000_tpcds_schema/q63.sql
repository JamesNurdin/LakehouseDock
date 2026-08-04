WITH
  intersect_items AS (
    SELECT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    INTERSECT
    SELECT inv.inv_item_sk AS item_sk
    FROM inventory inv
    JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
  ),
  ft_join AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state AS store_state,
      cc.cc_call_center_sk,
      cc.cc_name AS call_center_name,
      cc.cc_state AS call_center_state
    FROM store s
    FULL OUTER JOIN call_center cc
      ON s.s_state = cc.cc_state
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY COALESCE(ii.item_sk, ft.s_store_sk)) AS row_num,
  ii.item_sk,
  ft.s_store_sk,
  ft.s_store_name,
  ft.call_center_name,
  ft.store_state,
  ft.call_center_state
FROM intersect_items ii
FULL OUTER JOIN ft_join ft
  ON ii.item_sk = ft.s_store_sk
ORDER BY row_num
