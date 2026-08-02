WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        ca.ca_state,
        p.p_promo_name,
        p.p_discount_active,
        d.d_date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'IL')
      AND p.p_discount_active = 'Y'
      AND ss.ss_quantity > 1
      AND ss.ss_net_paid >= 100.00
),

returns_base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        rd.d_year,
        cd_r.cd_gender,
        ca_r.ca_state,
        r.r_reason_desc,
        sr.sr_returned_date_sk
    FROM store_returns sr
    JOIN date_dim rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN customer_demographics cd_r ON sr.sr_cdemo_sk = cd_r.cd_demo_sk
    JOIN customer_address ca_r ON sr.sr_addr_sk = ca_r.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE rd.d_year = 2001
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10.00
),

web_ret_base AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wd.d_year,
        cd_ref.cd_gender,
        ca_ref.ca_state,
        r_wr.r_reason_desc,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN date_dim wd ON wr.wr_returned_date_sk = wd.d_date_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE wd.d_year = 2001
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 5.00
),

sales_returns_full AS (
    SELECT
        COALESCE(s.d_year, r.d_year) AS d_year,
        COALESCE(s.ca_state, r.ca_state) AS ca_state,
        COALESCE(s.cd_gender, r.cd_gender) AS cd_gender,
        s.p_promo_name,
        s.p_discount_active,
        s.ss_net_paid,
        s.ss_ext_discount_amt,
        s.ss_net_profit,
        r.sr_return_amt,
        r.sr_net_loss
    FROM sales_base s
    FULL OUTER JOIN returns_base r
        ON s.ss_ticket_number = r.sr_ticket_number
),

state_agg AS (
    SELECT
        srfa.d_year,
        srfa.ca_state,
        srfa.cd_gender,
        SUM(srfa.ss_net_paid) AS total_net_paid,
        SUM(srfa.ss_ext_discount_amt) AS total_discount,
        SUM(srfa.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT srfa.p_promo_name) AS promo_count,
        SUM(COALESCE(srfa.sr_return_amt, 0)) AS total_return_amt,
        COUNT(srfa.sr_return_amt) AS return_rows,
        (
            SELECT SUM(srb.sr_return_amt)
            FROM returns_base srb
            WHERE srb.ca_state = srfa.ca_state
              AND srb.d_year = srfa.d_year
        ) AS total_state_return_amt
    FROM sales_returns_full srfa
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_ret_base w
        WHERE w.ca_state = srfa.ca_state
          AND w.d_year = srfa.d_year
    )
    GROUP BY srfa.d_year, srfa.ca_state, srfa.cd_gender
    HAVING SUM(srfa.ss_net_paid) > 5000
)

SELECT
    d_year,
    ca_state,
    cd_gender,
    total_net_paid,
    total_discount,
    total_net_profit,
    promo_count,
    total_return_amt,
    return_rows,
    total_state_return_amt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY d_year) AS year_total_net_profit
FROM state_agg
ORDER BY total_net_profit DESC
LIMIT 100
