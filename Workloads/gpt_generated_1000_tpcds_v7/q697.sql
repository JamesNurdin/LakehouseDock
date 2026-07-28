WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        d.d_year,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_quantity,
        cr.cr_return_quantity,
        wr.wr_return_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    d_year,
    i_category,
    i_brand,
    hd_buy_potential,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr_return_quantity, 0)) AS total_store_returns,
    SUM(COALESCE(cr_return_quantity, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr_return_quantity, 0)) AS total_web_returns,
    AVG(i_current_price) AS avg_current_price,
    AVG(ib_lower_bound) AS avg_income_lower_bound
FROM base
WHERE d_year BETWEEN 2000 AND 2002
  AND i_current_price > 100
  AND hd_buy_potential = '>10000'
  AND ib_lower_bound >= 80000
GROUP BY d_year, i_category, i_brand, hd_buy_potential
HAVING SUM(ss_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
