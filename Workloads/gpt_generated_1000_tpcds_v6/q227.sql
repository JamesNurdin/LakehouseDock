WITH agg_returns AS (
    SELECT
        s.s_store_id          AS store_id,
        d_ret.d_year          AS year,
        cd.cd_gender          AS gender,
        cp.cp_department      AS department,
        SUM(sr.sr_net_loss)          AS total_net_loss,
        SUM(sr.sr_refunded_cash)    AS total_refunded_cash,
        AVG(sr.sr_fee)              AS avg_fee,
        COUNT(*)                    AS return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t            ON sr.sr_return_time_sk   = t.t_time_sk
    JOIN customer c            ON sr.sr_customer_sk      = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk        = cd.cd_demo_sk
    JOIN customer_address ca   ON sr.sr_addr_sk          = ca.ca_address_sk
    JOIN store s               ON sr.sr_store_sk         = s.s_store_sk
    JOIN catalog_page cp       ON cp.cp_end_date_sk     = d_ret.d_date_sk
    WHERE
        s.s_state = 'CA'
        AND d_ret.d_year BETWEEN 2000 AND 2002
        AND t.t_hour BETWEEN 8 AND 20
        AND ca.ca_county LIKE '%County'
        AND cp.cp_department = 'Electronics'
        AND sr.sr_refunded_cash > 0
    GROUP BY
        s.s_store_id,
        d_ret.d_year,
        cd.cd_gender,
        cp.cp_department
)
SELECT
    store_id,
    year,
    SUM(total_net_loss)        AS store_year_net_loss,
    SUM(total_refunded_cash)   AS store_year_refunded_cash,
    SUM(return_cnt)            AS total_returns,
    AVG(avg_fee)               AS avg_fee_over_groups
FROM agg_returns
GROUP BY store_id, year
HAVING
    SUM(total_net_loss) > 10000
    AND SUM(return_cnt)   > 50
ORDER BY store_year_net_loss DESC
LIMIT 100
