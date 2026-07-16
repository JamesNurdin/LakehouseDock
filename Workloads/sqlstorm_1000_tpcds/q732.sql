WITH sales_base AS (
  SELECT
    s.s_store_sk,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_zip,
    d.d_year,
    d.d_month_seq,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_quantity,
    i.i_item_desc,
    i.i_color,
    i.i_product_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
),
item_agg AS (
  SELECT
    s_store_sk,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    s_zip,
    d_year,
    d_month_seq,
    i_item_desc,
    i_color,
    i_product_name,
    sum(ss_quantity) AS total_quantity,
    sum(ss_net_paid) AS net_paid_item,
    sum(ss_net_profit) AS net_profit_item,
    count(DISTINCT ss_ticket_number) AS distinct_tickets
  FROM sales_base
  GROUP BY
    s_store_sk,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    s_zip,
    d_year,
    d_month_seq,
    i_item_desc,
    i_color,
    i_product_name
),
top_items AS (
  SELECT
    s_store_sk,
    d_year,
    d_month_seq,
    i_product_name,
    total_quantity,
    row_number() OVER (PARTITION BY s_store_sk, d_year, d_month_seq ORDER BY total_quantity DESC) AS rn
  FROM item_agg
),
top5_agg AS (
  SELECT
    s_store_sk,
    d_year,
    d_month_seq,
    array_join(
      array_agg(
        concat(
          regexp_replace(lower(i_product_name), '\\s+', '_'),
          ':',
          CAST(total_quantity AS varchar)
        )
        ORDER BY total_quantity DESC
      ),
      ','
    ) AS top5_items
  FROM (
    SELECT *
    FROM top_items
    WHERE rn <= 5
  )
  GROUP BY
    s_store_sk,
    d_year,
    d_month_seq
)
SELECT
  s_store_sk,
  d_year,
  d_month_seq,
  top5_items
FROM top5_agg
