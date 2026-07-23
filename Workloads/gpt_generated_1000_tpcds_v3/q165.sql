WITH all_data AS (
    SELECT
        cc.cc_state,
        cp.cp_department,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        i.i_wholesale_cost,
        p.p_promo_id,
        p.p_channel_tv,
        p.p_purpose,
        r.r_reason_desc,
        t.t_hour,
        wp.wp_type,
        inv.inv_quantity_on_hand,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
)
SELECT
    d_year,
    i_category,
    CASE WHEN i_category = 'Electronics' THEN 'Electronics' ELSE 'Other' END AS category_group,
    SUM(wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(i_current_price) AS avg_price,
    MIN(inv_quantity_on_hand) AS min_inventory,
    SUM(CASE WHEN p_channel_tv = 'Y' THEN wr_return_amt ELSE 0 END) AS tv_promo_return_amount
FROM all_data
WHERE i_wholesale_cost > 5.0
  AND d_year = 2001
  AND t_hour BETWEEN 9 AND 17
GROUP BY d_year, i_category, CASE WHEN i_category = 'Electronics' THEN 'Electronics' ELSE 'Other' END
HAVING SUM(wr_return_amt) > 1000

UNION ALL

SELECT
    d_year,
    i_category,
    CASE WHEN i_category = 'Electronics' THEN 'Electronics' ELSE 'Other' END AS category_group,
    SUM(wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(i_current_price) AS avg_price,
    MIN(inv_quantity_on_hand) AS min_inventory,
    SUM(CASE WHEN p_channel_tv = 'Y' THEN wr_return_amt ELSE 0 END) AS tv_promo_return_amount
FROM all_data
WHERE i_wholesale_cost <= 5.0
  AND d_year = 2002
  AND t_hour BETWEEN 9 AND 17
GROUP BY d_year, i_category, CASE WHEN i_category = 'Electronics' THEN 'Electronics' ELSE 'Other' END
HAVING SUM(wr_return_amt) > 500

ORDER BY total_return_amount DESC
LIMIT 100
