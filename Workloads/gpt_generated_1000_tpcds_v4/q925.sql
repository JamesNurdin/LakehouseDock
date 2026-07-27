WITH item_store_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        s.s_state,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(wr.wr_return_quantity) AS web_return_cnt
    FROM store_returns sr
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        td_sr.t_shift = 'first'                         -- predicate 1
        AND td_wr.t_shift = 'first'                     -- predicate 2
        AND i.i_current_price > 20                      -- predicate 3
        AND i.i_current_price > (
                SELECT AVG(i2.i_current_price)
                FROM item i2
                WHERE i2.i_brand = i.i_brand
            )                                          -- predicate 4 (scalar subquery)
        AND s.s_state IN ('CA', 'TX', 'NY')             -- predicate 5
        AND cd.cd_gender = 'M'                          -- predicate 6
        AND inv.inv_quantity_on_hand > 0                -- predicate 7
        AND p.p_discount_active = 'Y'                   -- predicate 8
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        s.s_state
)
SELECT
    state,
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(total_net_loss) AS sum_total_net_loss,
    COUNT(*) AS num_items
FROM (
    SELECT
        s_state AS state,
        (store_return_amt + web_return_amt) AS total_return_amt,
        (store_net_loss + web_net_loss) AS total_net_loss
    FROM item_store_returns
) agg
WHERE total_return_amt > 100
GROUP BY state
HAVING SUM(total_net_loss) > 0
ORDER BY avg_total_return_amt DESC
LIMIT 100
