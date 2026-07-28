WITH catalog_agg AS (
   SELECT
       cs.cs_order_number,
       d_sale.d_year AS sale_year,
       d_ship.d_year AS ship_year,
       i.i_category,
       p.p_promo_name,
       sm.sm_type,
       c.c_customer_id,
       cd.cd_gender,
       hd.hd_income_band_sk,
       CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_count
   FROM catalog_sales cs
   JOIN date_dim d_sale ON cs.cs_sold_date_sk = d_sale.d_date_sk
   JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sale.d_date_sk
   LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk AND sr.sr_item_sk = i.i_item_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
   GROUP BY cs.cs_order_number,
            d_sale.d_year,
            d_ship.d_year,
            i.i_category,
            p.p_promo_name,
            sm.sm_type,
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_income_band_sk,
            CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
),
web_agg AS (
   SELECT
       ws.ws_order_number,
       d_sale.d_year AS sale_year,
       i.i_category,
       p.p_promo_name,
       sm.sm_type,
       c.c_customer_id,
       cd.cd_gender,
       hd.hd_income_band_sk,
       CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
       SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty
   FROM web_sales ws
   JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
   GROUP BY ws.ws_order_number,
            d_sale.d_year,
            i.i_category,
            p.p_promo_name,
            sm.sm_type,
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_income_band_sk,
            CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
)
SELECT *
FROM (
   SELECT
       cs_order_number   AS order_number,
       sale_year,
       ship_year,
       i_category,
       p_promo_name,
       sm_type,
       c_customer_id,
       cd_gender,
       hd_income_band_sk,
       profit_flag,
       total_sales,
       order_count,
       NULL               AS distinct_items,
       NULL               AS total_return_qty
   FROM catalog_agg
   UNION ALL
   SELECT
       ws_order_number   AS order_number,
       sale_year,
       NULL               AS ship_year,
       i_category,
       p_promo_name,
       sm_type,
       c_customer_id,
       cd_gender,
       hd_income_band_sk,
       profit_flag,
       total_sales,
       NULL               AS order_count,
       distinct_items,
       total_return_qty
   FROM web_agg
) final_result
ORDER BY total_sales DESC
LIMIT 100
