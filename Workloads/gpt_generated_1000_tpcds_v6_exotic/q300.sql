WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(CASE WHEN sr.sr_customer_sk IS NOT NULL THEN sr.sr_return_amt_inc_tax ELSE 0 END) AS store_return_amt,
        SUM(CASE WHEN wr.wr_refunded_customer_sk IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS web_return_amt,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
        SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND cp.cp_department = 'Books'
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    s.d_year,
    AVG(s.catalog_net_profit + s.web_net_profit) AS avg_total_net_profit,
    SUM(s.total_quantity) AS total_quantity_all,
    AVG(s.distinct_pages) AS avg_distinct_pages_per_customer,
    SUM(s.store_return_amt) AS total_store_returns,
    SUM(s.web_return_amt) AS total_web_returns
FROM sales_agg s
GROUP BY s.d_year
HAVING AVG(s.catalog_net_profit + s.web_net_profit) > 10000
ORDER BY s.d_year DESC
LIMIT 100
