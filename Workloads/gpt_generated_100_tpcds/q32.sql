WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_qty
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year,
             d.d_month_seq,
             s.s_store_name,
             ca.ca_state,
             cd.cd_gender,
             hd.hd_income_band_sk,
             i.i_category,
             r.r_reason_desc
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_name,
    a.ca_state,
    a.cd_gender,
    a.hd_income_band_sk,
    a.i_category,
    a.r_reason_desc,
    a.total_net_loss,
    a.total_qty,
    RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 10
