WITH base AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        d_ret.d_year,
        t.t_hour,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        wp.wp_type,
        ws.web_name,
        c.c_customer_sk,
        c.c_birth_month,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        (sr.sr_return_quantity * i.i_current_price) AS extended_price
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_ret.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'TX'
      AND w.w_gmt_offset = -6.00
      AND r.r_reason_desc LIKE '%damaged%'
      AND c.c_birth_month IN (1, 5, 6)
      AND sr.sr_return_quantity > 0
),
agg AS (
    SELECT
        s_state,
        i_category,
        SUM(extended_price) AS sum_extended_price,
        SUM(sr_net_loss) AS sum_net_loss,
        COUNT(*) AS cnt_returns,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(extended_price) DESC) AS rn_state
    FROM base
    GROUP BY ROLLUP (s_state, i_category)
    HAVING SUM(extended_price) > 1000
)
SELECT
    a.s_state,
    a.i_category,
    a.sum_extended_price,
    a.sum_net_loss,
    a.cnt_returns,
    a.rn_state,
    (SELECT COUNT(*) FROM base b2 WHERE b2.s_state = a.s_state AND b2.i_category = a.i_category) AS rows_in_group,
    (SELECT AVG(inner_sum) FROM (
            SELECT sr_store_sk, SUM(sr_net_loss) AS inner_sum
            FROM store_returns
            GROUP BY sr_store_sk
        ) q WHERE q.sr_store_sk = (
            SELECT sr.sr_store_sk FROM store_returns sr
            JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
            WHERE d.d_year = 2001 AND sr.sr_return_quantity > 0 LIMIT 1
        )) AS avg_store_loss
FROM agg a
WHERE a.rn_state <= 10
ORDER BY a.sum_extended_price DESC
LIMIT 100
