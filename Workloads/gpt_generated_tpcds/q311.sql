WITH base AS (
    SELECT
        date_dim.d_year,
        reason.r_reason_desc,
        customer_address.ca_state,
        SUM(web_returns.wr_return_amt) AS total_return_amt,
        SUM(web_returns.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(web_page.wp_char_count) AS avg_page_char_count
    FROM web_returns
    JOIN date_dim
        ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
    JOIN reason
        ON web_returns.wr_reason_sk = reason.r_reason_sk
    JOIN customer_address
        ON web_returns.wr_refunded_addr_sk = customer_address.ca_address_sk
    JOIN web_page
        ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
    WHERE date_dim.d_year = 2002
    GROUP BY
        date_dim.d_year,
        reason.r_reason_desc,
        customer_address.ca_state
),
total_reason AS (
    SELECT
        r_reason_desc,
        SUM(total_net_loss) AS reason_total_net_loss
    FROM base
    GROUP BY r_reason_desc
)
SELECT
    b.d_year,
    b.r_reason_desc,
    b.ca_state,
    b.total_return_amt,
    b.total_net_loss,
    b.return_cnt,
    b.avg_page_char_count,
    (b.total_net_loss / tr.reason_total_net_loss) * 100.0 AS net_loss_pct_of_reason,
    RANK() OVER (PARTITION BY b.r_reason_desc ORDER BY b.total_net_loss DESC) AS state_net_loss_rank
FROM base b
JOIN total_reason tr
    ON b.r_reason_desc = tr.r_reason_desc
ORDER BY
    b.r_reason_desc,
    state_net_loss_rank
