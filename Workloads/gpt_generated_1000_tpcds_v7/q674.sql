WITH joined AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_quantity,
        r.r_reason_desc,
        r.r_reason_id,
        ws.ws_web_site_sk,
        ws.ws_coupon_amt,
        ws.ws_ext_tax,
        ws.ws_sales_price,
        w.web_site_id,
        hd.hd_vehicle_count,
        hd.hd_dep_count
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count BETWEEN 1 AND 6
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND sr.sr_return_quantity > 0
      AND ws.ws_coupon_amt > 100
      AND ws.ws_ext_tax BETWEEN 10 AND 50
),
aggregated AS (
    SELECT
        web_site_id,
        r_reason_desc,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(*) AS transaction_cnt
    FROM joined
    GROUP BY web_site_id, r_reason_desc
)
SELECT
    web_site_id,
    r_reason_desc,
    total_return_amt,
    total_sales_price,
    transaction_cnt,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_return_amt DESC) AS return_rank
FROM aggregated
ORDER BY total_return_amt DESC
LIMIT 100
