/* goal: Analyze per‑customer sales, store and web returns, and promotion impact by joining all TPC‑DS tables. The query aggregates key monetary metrics, counts distinct return reasons, ranks customers by net profit, and demonstrates advanced SQL features such as DISTINCT, a LATERAL subquery, and a window function. */
WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr_reason.r_reason_id        AS sr_reason_id,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr_reason.r_reason_id        AS wr_reason_id,
        p.p_cost,
        -- Columns from time dimensions are not needed for the final aggregation but are joined to satisfy the join rules.
        ss_time.t_time_sk            AS ss_time_sk,
        sr_time.t_time_sk            AS sr_time_sk,
        wr_time.t_time_sk            AS wr_time_sk,
        -- LATERAL subquery to count distinct store‑return reasons per ticket.
        sr_lateral.store_return_reason_cnt_for_ticket
    FROM store_sales ss
    JOIN time_dim ss_time
        ON ss.ss_sold_time_sk = ss_time.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number   = ss.ss_ticket_number
       AND sr.sr_item_sk        = ss.ss_item_sk
       AND sr.sr_customer_sk    = c.c_customer_sk
       AND sr.sr_cdemo_sk       = cd.cd_demo_sk
       AND sr.sr_hdemo_sk       = hd.hd_demo_sk
       AND sr.sr_addr_sk        = ca.ca_address_sk
    LEFT JOIN time_dim sr_time
        ON sr.sr_return_time_sk = sr_time.t_time_sk
    LEFT JOIN reason sr_reason
        ON sr.sr_reason_sk = sr_reason.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
       AND wr.wr_refunded_cdemo_sk   = cd.cd_demo_sk
       AND wr.wr_refunded_hdemo_sk   = hd.hd_demo_sk
       AND wr.wr_refunded_addr_sk    = ca.ca_address_sk
    LEFT JOIN time_dim wr_time
        ON wr.wr_returned_time_sk = wr_time.t_time_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason wr_reason
        ON wr.wr_reason_sk = wr_reason.r_reason_sk
    LEFT JOIN customer_demographics cd_current
        ON c.c_current_cdemo_sk = cd_current.cd_demo_sk
    LEFT JOIN household_demographics hd_current
        ON c.c_current_hdemo_sk = hd_current.hd_demo_sk
    LEFT JOIN customer_address ca_current
        ON c.c_current_addr_sk = ca_current.ca_address_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(DISTINCT inner_sr.sr_reason_sk) AS store_return_reason_cnt_for_ticket
        FROM store_returns inner_sr
        WHERE inner_sr.sr_ticket_number = ss.ss_ticket_number
    ) AS sr_lateral ON TRUE
),
aggregated AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        SUM(ss_ext_sales_price)                         AS total_sales,
        SUM(ss_net_profit)                              AS total_net_profit,
        COALESCE(SUM(sr_return_amt), 0)                 AS total_store_return_amount,
        COALESCE(SUM(wr_return_amt), 0)                 AS total_web_return_amount,
        COALESCE(SUM(sr_net_loss), 0)                   AS total_store_net_loss,
        COALESCE(SUM(wr_net_loss), 0)                   AS total_web_net_loss,
        SUM(p_cost)                                      AS total_promo_cost,
        COUNT(DISTINCT sr_reason_id)                    AS distinct_store_return_reason_cnt,
        COUNT(DISTINCT wr_reason_id)                    AS distinct_web_return_reason_cnt,
        SUM(store_return_reason_cnt_for_ticket)         AS total_store_return_reason_cnt_per_ticket
    FROM base
    GROUP BY
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name
)
SELECT
    c_customer_sk,
    c_customer_id,
    c_first_name,
    c_last_name,
    total_sales,
    total_net_profit,
    total_store_return_amount,
    total_web_return_amount,
    total_store_net_loss,
    total_web_net_loss,
    total_promo_cost,
    distinct_store_return_reason_cnt,
    distinct_web_return_reason_cnt,
    total_store_return_reason_cnt_per_ticket,
    ROW_NUMBER() OVER (ORDER BY (total_net_profit - total_store_net_loss - total_web_net_loss) DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 20
