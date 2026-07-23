WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory_onhand,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        SUM(cs.cs_quantity) AS catalog_quantity_sold,
        SUM(ss.ss_quantity) AS store_quantity_sold,
        SUM(ws.ws_quantity) AS web_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND w.w_country = 'United States'
      AND ca.ca_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, c.c_customer_id, cd.cd_gender, hd.hd_income_band_sk, p.p_promo_name
)
SELECT
    d_year,
    d_month_seq,
    SUM(catalog_net_profit) AS total_catalog_profit,
    SUM(store_net_profit) AS total_store_profit,
    SUM(web_net_profit) AS total_web_profit,
    SUM(catalog_return_loss) AS total_return_loss,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(catalog_quantity_sold) AS total_catalog_qty,
    SUM(store_quantity_sold) AS total_store_qty,
    SUM(web_quantity_sold) AS total_web_qty,
    SUM(total_inventory_onhand) AS total_inventory,
    SUM(distinct_items_sold) AS total_distinct_items,
    (SUM(catalog_net_profit) + SUM(store_net_profit) + SUM(web_net_profit) - SUM(catalog_return_loss)) AS net_contribution
FROM sales_summary
GROUP BY d_year, d_month_seq
HAVING (SUM(catalog_net_profit) + SUM(store_net_profit) + SUM(web_net_profit) - SUM(catalog_return_loss)) > 0
ORDER BY net_contribution DESC
LIMIT 100
