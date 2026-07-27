WITH returns_reason_hd AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        r.r_reason_desc,
        hd.hd_buy_potential
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)service|warranty')
      AND hd.hd_buy_potential LIKE '%-%'
)
SELECT
    CONCAT('Potential: ', rr.hd_buy_potential) AS buy_potential_label,
    rr.r_reason_desc,
    COUNT(DISTINCT rr.wr_order_number) AS returns_cnt,
    SUM(rr.wr_return_amt) AS total_return_amount,
    SUM(rr.wr_net_loss) AS total_net_loss,
    ROUND(SUM(rr.wr_return_amt) / avg_tbl.avg_return_amt, 2) AS return_amount_vs_avg
FROM returns_reason_hd rr
JOIN web_sales ws
    ON rr.wr_order_number = ws.ws_order_number
CROSS JOIN (
    SELECT AVG(wr_return_amt) AS avg_return_amt
    FROM web_returns
) avg_tbl
WHERE ws.ws_sales_price > 1000
GROUP BY rr.hd_buy_potential, rr.r_reason_desc, avg_tbl.avg_return_amt
ORDER BY total_net_loss DESC
LIMIT 100
