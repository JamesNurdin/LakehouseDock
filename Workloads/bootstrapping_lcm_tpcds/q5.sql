WITH catalog_agg AS (
    SELECT
        cr_returned_date_sk,
        SUM(cr_return_amount) AS cat_return_total,
        SUM(cr_net_loss) AS cat_net_loss,
        COUNT(DISTINCT cr_order_number) AS cat_order_cnt
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
store_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_store_sk,
        SUM(sr_return_amt) AS store_return_total,
        SUM(sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT sr_ticket_number) AS store_ticket_cnt
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk
),
web_agg AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_amt) AS web_return_total,
        SUM(wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT wr_order_number) AS web_order_cnt
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    ca.cat_order_cnt,
    ca.cat_return_total,
    sa.store_ticket_cnt,
    sa.store_return_total,
    wa.web_order_cnt,
    wa.web_return_total,
    (ca.cat_net_loss + sa.store_net_loss + wa.web_net_loss) AS total_net_loss
FROM date_dim d
JOIN catalog_agg ca
    ON ca.cr_returned_date_sk = d.d_date_sk
JOIN web_agg wa
    ON wa.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_agg sa
    ON sa.sr_returned_date_sk = d.d_date_sk
   AND sa.sr_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2000 AND 2002
ORDER BY total_net_loss DESC
LIMIT 100
