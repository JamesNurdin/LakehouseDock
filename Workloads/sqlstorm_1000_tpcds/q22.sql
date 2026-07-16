WITH sales_str AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_product_name,
    i.i_item_desc,
    i.i_color,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    regexp_replace(upper(trim(i.i_product_name)), '\\W', '') AS prod_name_clean,
    cardinality(split(regexp_replace(i.i_item_desc, '[.,]', ''), '\\s+')) AS desc_word_count,
    CAST(ws.ws_sales_price * ws.ws_quantity AS DOUBLE) AS total_sales,
    CAST(ws.ws_net_profit * ws.ws_quantity AS DOUBLE) AS total_profit
  FROM
    web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE
    d.d_year = 2001
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  prod_name_clean,
  SUM(total_sales) AS sum_sales,
  SUM(total_profit) AS sum_profit,
  AVG(ws_quantity) AS avg_quantity,
  MAX(desc_word_count) AS max_desc_word_count
FROM
  sales_str
GROUP BY
  d_year,
  d_month_seq,
  i_category,
  prod_name_clean
