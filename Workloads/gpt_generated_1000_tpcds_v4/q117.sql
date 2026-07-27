WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_net_paid)        AS total_net_paid,
        SUM(cs.cs_net_profit)      AS total_net_profit,
        COUNT(*)                   AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim   d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim   t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN item       i      ON cs.cs_item_sk      = i.i_item_sk
    GROUP BY
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    i.i_item_id,
    i.i_product_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_net_paid,
    sa.total_net_profit,
    sm.sm_type               AS ship_mode_type,
    cp.cp_department,
    p.p_promo_name,
    COALESCE(rtn.total_return_qty, 0)      AS total_return_qty,
    COALESCE(wr.total_web_return_qty, 0)   AS total_web_return_qty,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sa.total_net_profit DESC) AS profit_rank,
    (
        SELECT AVG(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    ) AS avg_active_promo_cost
FROM sales_agg sa
JOIN item        i   ON sa.cs_item_sk      = i.i_item_sk
JOIN catalog_page cp  ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode   sm  ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion   p   ON sa.cs_promo_sk    = p.p_promo_sk
JOIN time_dim    t_sold ON sa.cs_sold_time_sk = t_sold.t_time_sk
-- catalog_page start / end dates (date_dim reused with aliases)
JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end   ON cp.cp_end_date_sk   = d_page_end.d_date_sk
-- promotion start / end dates (date_dim reused with aliases)
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end   ON p.p_end_date_sk   = d_promo_end.d_date_sk
LEFT JOIN (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason   r     ON cr.cr_reason_sk      = r.r_reason_sk
    GROUP BY cr.cr_item_sk
) rtn ON rtn.cr_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_web_return_qty
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp   ON wr.wr_web_page_sk    = wp.wp_web_page_sk
    JOIN reason   r2   ON wr.wr_reason_sk      = r2.r_reason_sk
    GROUP BY wr.wr_item_sk
) wr ON wr.wr_item_sk = i.i_item_sk
WHERE sa.d_year = 2001
ORDER BY sa.total_net_profit DESC
LIMIT 100
