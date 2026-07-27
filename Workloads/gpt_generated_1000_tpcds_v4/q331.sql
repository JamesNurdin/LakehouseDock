WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
      AND ss.ss_sales_price > 0
      AND ss.ss_net_paid_inc_tax > 0
      AND ss.ss_sold_time_sk IS NOT NULL
    GROUP BY ss.ss_store_sk,
             ss.ss_item_sk,
             ss.ss_customer_sk,
             ss.ss_cdemo_sk,
             ss.ss_addr_sk,
             ss.ss_promo_sk,
             ss.ss_sold_time_sk
),
cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
    GROUP BY cs.cs_item_sk,
             cs.cs_sold_time_sk,
             cs.cs_promo_sk,
             cs.cs_catalog_page_sk
),
wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_return_amt_inc_tax > 0
      AND wr.wr_returned_time_sk IS NOT NULL
    GROUP BY wr.wr_item_sk,
             wr.wr_returned_time_sk
)
SELECT DISTINCT
    s.s_store_name,
    i.i_product_name,
    p.p_promo_name,
    t.t_hour,
    cd.cd_gender,
    ca.ca_state,
    cp.cp_department,
    ss_agg.store_sales_cnt,
    ss_agg.total_store_profit,
    cs_agg.catalog_sales_cnt,
    cs_agg.total_catalog_net_paid,
    wr_agg.return_cnt,
    wr_agg.total_return_amount,
    inv.inv_quantity_on_hand
FROM ss_agg
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss_agg.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
  ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN customer c
  ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
JOIN cs_agg
  ON ss_agg.ss_item_sk = cs_agg.cs_item_sk
 AND ss_agg.ss_sold_time_sk = cs_agg.cs_sold_time_sk
 AND ss_agg.ss_promo_sk = cs_agg.cs_promo_sk
JOIN catalog_page cp
  ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN wr_agg
  ON wr_agg.wr_item_sk = i.i_item_sk
 AND wr_agg.wr_returned_time_sk = t.t_time_sk
WHERE s.s_state = 'CA'
  AND i.i_brand = 'BrandX'
  AND p.p_channel_email = 'N'
  AND t.t_hour BETWEEN 9 AND 17
  AND cd.cd_marital_status = 'M'
ORDER BY ss_agg.total_store_profit DESC
LIMIT 100
