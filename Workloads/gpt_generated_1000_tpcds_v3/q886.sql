WITH sales_summary AS (
    SELECT
        s.s_store_id,
        i.i_item_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(ws.ws_net_profit) AS web_sales_net_profit,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_sales
    FROM
        date_dim d
        JOIN store s
            ON s.s_closed_date_sk = d.d_date_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_store_sk = s.s_store_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_item_sk = i.i_item_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
            AND cp.cp_start_date_sk = d.d_date_sk
        JOIN ship_mode sm_cs
            ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_item_sk = i.i_item_sk
            AND sr.sr_cdemo_sk = cd.cd_demo_sk
            AND sr.sr_store_sk = s.s_store_sk
        JOIN reason r_sr
            ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN inventory inv
            ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm_ws
            ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN web_returns wr
            ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_item_sk = i.i_item_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
            AND wr.wr_returning_cdemo_sk = cd.cd_demo_sk
        JOIN reason r_wr
            ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        d.d_year = 2001
        AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        AND i.i_size = 'medium'
        AND cd.cd_gender = 'F'
        AND sm_cs.sm_code = 'AIR'
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        s.s_store_id,
        i.i_item_id,
        d.d_year
)
SELECT
    ss.s_store_id,
    ss.i_item_id,
    ss.d_year,
    ss.store_sales_net_paid,
    ss.store_sales_net_profit,
    ss.catalog_sales_net_paid,
    ss.web_sales_net_paid,
    ss.total_inventory,
    (ss.store_sales_net_profit + ss.catalog_sales_net_profit + ss.web_sales_net_profit) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY (ss.store_sales_net_profit + ss.catalog_sales_net_profit + ss.web_sales_net_profit) DESC) AS profit_rank
FROM
    sales_summary ss
WHERE
    ss.total_inventory > 0
    AND ss.store_sales_net_profit > 0
    AND ss.catalog_sales_net_paid > 0
    AND ss.web_sales_net_paid > 0
    AND (ss.store_sales_net_profit + ss.catalog_sales_net_profit + ss.web_sales_net_profit) > (
        SELECT AVG(inner_total)
        FROM (
            SELECT (store_sales_net_profit + catalog_sales_net_profit + web_sales_net_profit) AS inner_total
            FROM sales_summary
        ) t
    )
ORDER BY
    ss.d_year,
    profit_rank
LIMIT 100
