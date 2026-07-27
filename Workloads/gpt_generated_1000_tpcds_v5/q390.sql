WITH
    web_agg AS (
        SELECT
            wr_returned_date_sk,
            SUM(wr_net_loss) AS web_net_loss,
            COUNT(*) AS web_return_cnt
        FROM web_returns
        WHERE wr_returned_date_sk IS NOT NULL
        GROUP BY wr_returned_date_sk
    ),
    store_agg AS (
        SELECT
            d.d_year,
            r.r_reason_desc,
            ib.ib_lower_bound,
            COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
            SUM(sr.sr_net_loss) AS store_net_loss,
            AVG(sr.sr_return_quantity) AS avg_store_qty,
            COALESCE(w.web_net_loss, 0) AS web_net_loss,
            COALESCE(w.web_return_cnt, 0) AS web_return_cnt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_agg w ON sr.sr_returned_date_sk = w.wr_returned_date_sk
        WHERE d.d_year = 2001
          AND hd.hd_vehicle_count > 2
          AND ib.ib_upper_bound <= 100000
          AND cd.cd_credit_rating = 'Good'
          AND EXISTS (
                SELECT 1
                FROM web_returns wr
                WHERE wr.wr_returned_date_sk = d.d_date_sk
                  AND wr.wr_return_quantity > 5
          )
        GROUP BY d.d_year, r.r_reason_desc, ib.ib_lower_bound, w.web_net_loss, w.web_return_cnt
    )
SELECT
    d_year,
    r_reason_desc,
    ib_lower_bound,
    store_return_cnt,
    store_net_loss,
    web_net_loss,
    web_return_cnt,
    avg_store_qty,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (store_net_loss + web_net_loss) DESC) AS loss_rank
FROM store_agg
ORDER BY loss_rank
LIMIT 100
