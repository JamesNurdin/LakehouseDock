-- Goal: Rank product return reasons by total net loss for recent items, showing loss category and average loss per reason.
WITH joined AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        cr.cr_returned_date_sk,
        i.i_item_id,
        i.i_product_name,
        sr.sr_returned_date_sk AS sr_return_date,
        sr.sr_net_loss,
        r.r_reason_id,
        r.r_reason_desc,
        c.c_customer_id,
        ws.ws_ext_sales_price,
        p.p_promo_id
    FROM call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN item i
        ON i.i_item_sk = cr.cr_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN customer c
        ON c.c_customer_sk = sr.sr_customer_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_promo_sk = ws.ws_promo_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_end_date   <= DATE '2005-12-31'
      AND cc.cc_gmt_offset    > 0
      AND ws.ws_ext_sales_price > 1000
),
agg AS (
    SELECT
        r_reason_id,
        r_reason_desc,
        SUM(sr_net_loss)                         AS total_net_loss,
        COUNT(DISTINCT c_customer_id)             AS distinct_customers,
        CASE WHEN SUM(sr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM joined
    GROUP BY r_reason_id, r_reason_desc
)
SELECT
    a.r_reason_id,
    a.r_reason_desc,
    a.total_net_loss,
    a.distinct_customers,
    a.loss_category,
    (SELECT AVG(j.sr_net_loss)
       FROM joined j
       WHERE j.r_reason_id = a.r_reason_id)      AS avg_loss_per_reason,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
