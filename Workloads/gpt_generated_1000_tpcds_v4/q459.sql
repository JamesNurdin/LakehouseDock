WITH base AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_year,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        ca.ca_gmt_offset,
        s.s_store_name,
        r.r_reason_desc,
        wr.wr_return_amt AS web_return_amt,
        i.inv_quantity_on_hand,
        cp.cp_type,
        ws.web_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON d.d_date_sk = wr.wr_returned_date_sk
    JOIN inventory i ON d.d_date_sk = i.inv_date_sk
    JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
    JOIN web_site ws ON d.d_date_sk = ws.web_open_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_gmt_offset = -5.00
      AND ib.ib_upper_bound > 50000
      AND cp.cp_type = 'A'
)
SELECT
    d_year,
    s_store_name,
    r_reason_desc,
    COUNT(DISTINCT sr_ticket_number) AS num_returns,
    SUM(sr_return_amt) AS total_store_return_amt,
    SUM(web_return_amt) AS total_web_return_amt,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    CASE
        WHEN SUM(sr_return_amt) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS return_level,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound
FROM base
GROUP BY d_year, s_store_name, r_reason_desc
ORDER BY total_store_return_amt DESC
LIMIT 100
