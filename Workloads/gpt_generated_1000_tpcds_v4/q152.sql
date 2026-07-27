WITH sales_cte AS (
    SELECT
        ss.ss_sold_date_sk      AS sold_date_sk,
        ss.ss_sold_time_sk      AS sold_time_sk,
        ss.ss_item_sk           AS item_sk,
        ss.ss_store_sk          AS store_sk,
        ss.ss_ticket_number    AS ticket_number,
        s.s_store_id            AS store_id,
        i.i_item_id             AS item_id,
        d.d_year                AS year,
        d.d_month_seq           AS month_seq,
        SUM(ss.ss_net_profit)   AS total_net_profit,
        SUM(ss.ss_quantity)     AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    JOIN store s           ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND i.i_brand = 'Brand#12'
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        s.s_store_id,
        i.i_item_id,
        d.d_year,
        d.d_month_seq
    HAVING SUM(ss.ss_quantity) > 100
)
SELECT DISTINCT
    sc.store_id,
    sc.item_id,
    cp.cp_department,
    sm.sm_type,
    r.r_reason_desc,
    wsite.web_name,
    inv.inv_quantity_on_hand,
    sc.profit_rank,
    sc.total_net_profit,
    CASE WHEN sc.profit_rank = 1 THEN 'Top Performer' ELSE 'Other' END AS performance_category
FROM sales_cte sc
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = sc.sold_date_sk
   AND cr.cr_item_sk = sc.item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = sc.sold_date_sk
   AND ws.ws_item_sk = sc.item_sk
   AND ws.ws_order_number = sc.ticket_number
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = sc.sold_date_sk
   AND wr.wr_item_sk = sc.item_sk
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN inventory inv
    ON inv.inv_date_sk = sc.sold_date_sk
   AND inv.inv_item_sk = sc.item_sk
ORDER BY sc.profit_rank ASC, sc.total_net_profit DESC
LIMIT 100
