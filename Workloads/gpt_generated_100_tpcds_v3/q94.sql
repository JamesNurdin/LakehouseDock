WITH base AS (
    SELECT
        d.d_year AS d_year,
        i.i_item_sk AS i_item_sk,
        i.i_product_name AS i_product_name,
        i.i_category AS i_category,
        i.i_brand_id AS i_brand_id,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS cs_profit_flag
    FROM date_dim d
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN web_site wsit ON wsit.web_open_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND i.i_brand_id = 15
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
),
agg AS (
    SELECT
        d_year,
        i_item_sk,
        i_product_name,
        i_category,
        i_brand_id,
        SUM(cs_ext_sales_price) AS total_cs_sales,
        SUM(ss_ext_sales_price) AS total_ss_sales,
        SUM(ws_ext_sales_price) AS total_ws_sales,
        SUM(cs_net_profit) AS total_cs_profit,
        SUM(ss_net_profit) AS total_ss_profit,
        SUM(ws_net_profit) AS total_ws_profit,
        COALESCE(SUM(sr_net_loss), 0) AS total_returns_loss,
        CASE WHEN SUM(cs_net_profit) + SUM(ss_net_profit) + SUM(ws_net_profit) - COALESCE(SUM(sr_net_loss), 0) > 0
            THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_profit_flag
    FROM base
    GROUP BY d_year, i_item_sk, i_product_name, i_category, i_brand_id
)
SELECT
    d_year,
    i_item_sk,
    i_product_name,
    i_category,
    i_brand_id,
    total_cs_sales,
    total_ss_sales,
    total_ws_sales,
    total_cs_profit + total_ss_profit + total_ws_profit - total_returns_loss AS net_total_profit,
    overall_profit_flag,
    RANK() OVER (ORDER BY (total_cs_profit + total_ss_profit + total_ws_profit - total_returns_loss) DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
