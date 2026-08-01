WITH web_return_agg AS (
    SELECT
        wr.wr_item_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_return_amt) AS web_total_return_amt
    FROM web_returns wr
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    GROUP BY wr.wr_item_sk
)
SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    td_ss.t_hour,
    i_ss.i_product_name,
    hd_ss.hd_income_band_sk,
    COALESCE(ss.ss_net_paid, 0) AS net_paid,
    COALESCE(sr.sr_return_amt, 0) AS return_amt,
    COALESCE(cs.cs_net_paid, 0) AS catalog_net_paid,
    wra.web_return_cnt,
    wra.web_total_return_amt,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ss.ss_item_sk
          AND sr2.sr_returned_date_sk > ss.ss_sold_date_sk
    ) AS future_store_return_cnt
FROM store_sales ss
JOIN time_dim td_ss
    ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN item i_ss
    ON ss.ss_item_sk = i_ss.i_item_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = ss.ss_item_sk
JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN item i_cs
    ON cs.cs_item_sk = i_cs.i_item_sk
LEFT JOIN web_return_agg wra
    ON wra.wr_item_sk = ss.ss_item_sk
WHERE ss.ss_net_paid > 0
ORDER BY net_paid DESC
LIMIT 100
