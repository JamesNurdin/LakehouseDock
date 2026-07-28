WITH joined AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        ss.ss_ext_sales_price,
        wr.wr_return_amt,
        d_cs.d_year AS year,
        s.s_state AS state,
        i.i_category,
        p.p_discount_active,
        w.w_gmt_offset,
        inv.inv_quantity_on_hand,
        ws.web_tax_percentage
    FROM catalog_sales cs
    JOIN date_dim d_cs                     ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN customer c_bill                   ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN item i                            ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                       ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w                       ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss                    ON cs.cs_item_sk = ss.ss_item_sk
    JOIN date_dim d_ss                     ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN store s                           ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr                    ON cs.cs_item_sk = wr.wr_item_sk
    JOIN date_dim d_wr                     ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp                       ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation            ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access              ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN inventory inv                     ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv                    ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN web_site ws                       ON ws.web_open_date_sk = d_inv.d_date_sk
    JOIN date_dim d_ws_open                ON ws.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close               ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN date_dim d_store_closed           ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cust_first_ship       ON c_bill.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
    JOIN date_dim d_cust_first_sales      ON c_bill.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
    WHERE d_cs.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND w.w_gmt_offset BETWEEN -5.00 AND -4.00
      AND inv.inv_quantity_on_hand > 0
      AND ws.web_tax_percentage > 5.0
),
aggregated AS (
    SELECT
        year,
        state,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs_net_profit)      AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(wr_return_amt)      AS total_return_amount
    FROM joined
    GROUP BY ROLLUP (year, state)
)
SELECT
    year,
    state,
    total_catalog_sales,
    total_store_sales,
    total_return_amount,
    catalog_order_cnt,
    CASE WHEN total_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    SUM(total_catalog_sales) OVER (PARTITION BY year) AS catalog_sales_year_total
FROM aggregated
ORDER BY year, state
LIMIT 100
