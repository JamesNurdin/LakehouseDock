SELECT
    store.s_store_id,
    store.s_store_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    item.i_category,
    sum(store_sales.ss_ext_sales_price) AS total_sales,
    sum(store_sales.ss_ext_discount_amt) AS total_discount,
    sum(store_sales.ss_net_profit) AS total_profit
FROM store_sales
JOIN store
  ON store_sales.ss_store_sk = store.s_store_sk
JOIN date_dim
  ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
JOIN item
  ON store_sales.ss_item_sk = item.i_item_sk
WHERE date_dim.d_year = 2001
GROUP BY
    store.s_store_id,
    store.s_store_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    item.i_category
ORDER BY total_profit DESC
LIMIT 100
