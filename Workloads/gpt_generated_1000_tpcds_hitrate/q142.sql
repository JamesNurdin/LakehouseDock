WITH agg_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price)               AS store_sales,
        SUM(cs.cs_ext_sales_price)               AS catalog_sales,
        SUM(ws.ws_ext_sales_price)               AS web_sales,
        SUM(wr.wr_return_amt)                    AS total_returns,
        SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                               AND cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
                               AND inv.inv_date_sk = d.d_date_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                               AND ws.ws_sold_date_sk = d.d_date_sk
                               AND ws.ws_bill_addr_sk = ca.ca_address_sk
                               AND ws.ws_ship_addr_sk = ca.ca_address_sk
                               AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                               AND ws.ws_warehouse_sk = w.w_warehouse_sk
                               AND ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                               AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002                     -- predicate 1
        AND w.w_country = 'United States'                  -- predicate 2
        AND we.web_state = 'CA'                           -- predicate 3
        AND ca.ca_state = 'CA'                            -- predicate 4
        AND sm.sm_type = 'AIR'                            -- predicate 5
        AND p.p_discount_active = 'Y'                     -- predicate 6
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        d.d_year
),
yearly_item_cnt AS (
    SELECT
        d_year,
        COUNT(DISTINCT i_item_id) AS item_cnt
    FROM agg_sales
    GROUP BY d_year
)
SELECT
    a.i_item_id,
    a.d_year,
    a.total_profit,
    a.total_profit / NULLIF(c.item_cnt, 0) AS avg_profit_per_item,
    (SELECT COUNT(*) FROM warehouse w2 WHERE w2.w_country = 'United States') AS us_warehouse_cnt
FROM agg_sales a
JOIN yearly_item_cnt c ON c.d_year = a.d_year
WHERE a.total_profit > 10000
ORDER BY a.total_profit DESC
LIMIT 100
