WITH unified_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS channel_sk,
           'store' AS channel_type,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           ss_ext_discount_amt AS discount_amt,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_page_sk,
           'web',
           ws_net_paid,
           ws_net_profit,
           ws_ext_discount_amt,
           ws_quantity
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_call_center_sk,
           'catalog',
           cs_net_paid,
           cs_net_profit,
           cs_ext_discount_amt,
           cs_quantity
    FROM catalog_sales
),
sales_by_channel_year AS (
    SELECT d.d_year,
           us.channel_type,
           sum(us.net_paid) AS total_net_paid,
           sum(us.net_profit) AS total_net_profit,
           avg(us.discount_amt) AS avg_discount,
           approx_distinct(us.item_sk) AS distinct_items,
           sum(us.quantity) AS total_quantity
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    GROUP BY d.d_year, us.channel_type
),
item_profit AS (
    SELECT d.d_year,
           us.channel_type,
           us.item_sk,
           sum(us.net_profit) AS item_net_profit,
           sum(us.net_paid) AS item_net_paid,
           sum(us.quantity) AS item_quantity
    FROM unified_sales us
    JOIN date_dim d ON us.date_sk = d.d_date_sk
    GROUP BY d.d_year, us.channel_type, us.item_sk
),
top_items AS (
    SELECT ip.d_year,
           ip.channel_type,
           ip.item_sk,
           ip.item_net_profit,
           row_number() OVER (PARTITION BY ip.d_year, ip.channel_type ORDER BY ip.item_net_profit DESC) AS rn
    FROM item_profit ip
)
SELECT scy.d_year,
       scy.channel_type,
       scy.total_net_paid,
       scy.total_net_profit,
       scy.avg_discount,
       scy.distinct_items,
       scy.total_quantity,
       ti.item_sk,
       i.i_product_name,
       ti.item_net_profit,
       ti.rn AS item_rank
FROM sales_by_channel_year scy
JOIN top_items ti
  ON scy.d_year = ti.d_year
 AND scy.channel_type = ti.channel_type
 AND ti.rn <= 5
JOIN item i
  ON ti.item_sk = i.i_item_sk
ORDER BY scy.d_year, scy.channel_type, ti.rn
