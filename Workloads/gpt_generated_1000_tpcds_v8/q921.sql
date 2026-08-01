WITH base AS (
    SELECT
        s.s_store_id,
        i.i_item_id,
        d.d_year,
        SUM(ss.ss_net_paid)               AS store_sales_net,
        SUM(cs.cs_net_paid)               AS catalog_sales_net,
        SUM(ws.ws_net_paid)               AS web_sales_net,
        SUM(inv.inv_quantity_on_hand)     AS inventory_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales ss
        JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN promotion p        ON ss.ss_promo_sk = p.p_promo_sk                 -- outer join requirement
        JOIN catalog_sales cs        ON cs.cs_item_sk = i.i_item_sk
                                     AND cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN call_center cc    ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w             ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws            ON ws.ws_item_sk = i.i_item_sk
                                     AND ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr     ON wr.wr_order_number = ws.ws_order_number
                                     AND wr.wr_item_sk = i.i_item_sk
                                     AND wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN reason r           ON wr.wr_reason_sk = r.r_reason_sk
        JOIN inventory inv TABLESAMPLE BERNOULLI (10) ON inv.inv_item_sk = i.i_item_sk
                                                  AND inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        AND i.i_category = 'Sports'
        AND ca.ca_gmt_offset = -5.00
        AND p.p_discount_active = 'Y'
        AND s.s_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_order_number = ws.ws_order_number
              AND ws2.ws_quantity > 5
        )
    GROUP BY
        s.s_store_id,
        i.i_item_id,
        d.d_year
)
SELECT
    s_store_id,
    i_item_id,
    d_year,
    store_sales_net,
    catalog_sales_net,
    web_sales_net,
    inventory_qty,
    sales_rank
FROM base
WHERE sales_rank <= 5
UNION DISTINCT
SELECT
    s_store_id,
    i_item_id,
    d_year,
    store_sales_net,
    catalog_sales_net,
    web_sales_net,
    inventory_qty,
    sales_rank
FROM base
WHERE sales_rank > 5 AND sales_rank <= 10
ORDER BY d_year DESC, store_sales_net DESC
LIMIT 100
