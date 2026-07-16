WITH combined_sales AS (
  SELECT
    ss_sold_date_sk AS date_sk,
    ss_item_sk AS item_sk,
    ss_store_sk AS store_sk,
    ss_promo_sk AS promo_sk,
    ss_ticket_number AS ticket_number,
    ss_quantity AS quantity,
    ss_ext_discount_amt AS ext_discount_amt,
    ss_ext_sales_price AS ext_sales_price,
    ss_net_paid AS net_paid,
    ss_net_paid_inc_tax AS net_paid_inc_tax,
    ss_net_profit AS net_profit,
    'store' AS channel,
    ss_cdemo_sk AS cdemo_sk,
    ss_hdemo_sk AS hdemo_sk
  FROM store_sales
  UNION ALL
  SELECT
    cs_sold_date_sk,
    cs_item_sk,
    cs_call_center_sk,
    cs_promo_sk,
    cs_order_number,
    cs_quantity,
    cs_ext_discount_amt,
    cs_ext_sales_price,
    cs_net_paid,
    cs_net_paid_inc_tax,
    cs_net_profit,
    'catalog',
    cs_bill_cdemo_sk,
    cs_bill_hdemo_sk
  FROM catalog_sales
  UNION ALL
  SELECT
    ws_sold_date_sk,
    ws_item_sk,
    ws_web_page_sk,
    ws_promo_sk,
    ws_order_number,
    ws_quantity,
    ws_ext_discount_amt,
    ws_ext_sales_price,
    ws_net_paid,
    ws_net_paid_inc_tax,
    ws_net_profit,
    'web',
    ws_bill_cdemo_sk,
    ws_bill_hdemo_sk
  FROM web_sales
),
sales_with_dim AS (
  SELECT
    cs.date_sk,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_category_id,
    i.i_brand,
    i.i_item_id,
    cs.item_sk,
    cs.channel,
    cs.store_sk,
    cs.cdemo_sk,
    cs.hdemo_sk,
    cs.quantity,
    cs.ext_discount_amt,
    cs.ext_sales_price,
    cs.net_paid,
    cs.net_paid_inc_tax,
    cs.net_profit
  FROM combined_sales cs
  LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
  LEFT JOIN item i ON cs.item_sk = i.i_item_sk
),
customer_demo AS (
  SELECT
    cd_demo_sk,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_credit_rating
  FROM customer_demographics
),
household_demo AS (
  SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_buy_potential,
    hd_dep_count
  FROM household_demographics
),
agg AS (
  SELECT
    d_year,
    channel,
    i_category,
    SUM(net_profit) AS total_net_profit,
    SUM(net_paid_inc_tax) AS total_net_paid_inc_tax,
    SUM(ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt,
    AVG(net_profit) AS avg_profit,
    SUM(quantity) AS total_quantity
  FROM sales_with_dim swd
  LEFT JOIN customer_demo cd ON swd.cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demo hd ON swd.hdemo_sk = hd.hd_demo_sk
  GROUP BY d_year, channel, i_category
),
ranked AS (
  SELECT
    d_year,
    channel,
    i_category,
    total_net_profit,
    total_net_paid_inc_tax,
    total_discount,
    sales_cnt,
    avg_profit,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_net_profit DESC) AS category_rank_by_profit,
    total_net_profit / SUM(total_net_profit) OVER (PARTITION BY d_year, channel) * 100 AS profit_share_pct
  FROM agg
)
SELECT
  d_year,
  channel,
  i_category,
  total_net_profit,
  total_net_paid_inc_tax,
  total_discount,
  sales_cnt,
  avg_profit,
  total_quantity,
  category_rank_by_profit,
  profit_share_pct
FROM ranked
WHERE category_rank_by_profit <= 5
ORDER BY d_year, channel, category_rank_by_profit
