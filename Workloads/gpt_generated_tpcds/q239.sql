WITH returns_detail AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        s.s_state,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        t.t_hour,
        sr.sr_item_sk,
        i.i_category,
        i.i_current_price,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        r.r_reason_desc,
        sr.sr_customer_sk,
        c.c_current_hdemo_sk,
        hd.hd_buy_potential,
        sr.sr_addr_sk,
        ca.ca_state
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_returned_date_sk BETWEEN 2451910 AND 2451970
),
aggregated AS (
    SELECT
        s_store_name,
        sr_returned_date_sk,
        t_hour,
        r_reason_desc,
        hd_buy_potential,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT i_category) AS distinct_categories_returned,
        AVG(i_current_price) AS avg_item_price
    FROM returns_detail
    GROUP BY
        s_store_name,
        sr_returned_date_sk,
        t_hour,
        r_reason_desc,
        hd_buy_potential
)
SELECT
    s_store_name,
    sr_returned_date_sk,
    t_hour,
    r_reason_desc,
    hd_buy_potential,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    distinct_categories_returned,
    avg_item_price,
    RANK() OVER (PARTITION BY sr_returned_date_sk ORDER BY total_net_loss DESC) AS store_daily_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
