WITH combined AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        i.i_item_id AS item_id,
        i.i_size AS item_size,
        cd.cd_gender AS customer_gender,
        hd.hd_income_band_sk AS income_band,
        cs.cs_net_paid AS net_paid,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
        CASE WHEN EXISTS (
            SELECT 1 FROM web_returns wr WHERE wr.wr_item_sk = cs.cs_item_sk
        ) THEN 1 ELSE 0 END AS has_returned,
        (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS return_count
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_size IN ('large', 'medium')
      AND hd.hd_income_band_sk > 10
      AND cs.cs_net_paid >= 100
    UNION ALL
    SELECT
        ss.ss_ticket_number AS order_number,
        ss.ss_sold_date_sk AS sold_date_sk,
        i.i_item_id AS item_id,
        i.i_size AS item_size,
        cd.cd_gender AS customer_gender,
        hd.hd_income_band_sk AS income_band,
        ss.ss_net_paid AS net_paid,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
        CASE WHEN EXISTS (
            SELECT 1 FROM web_returns wr WHERE wr.wr_item_sk = ss.ss_item_sk
        ) THEN 1 ELSE 0 END AS has_returned,
        (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS return_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_size IN ('large', 'medium')
      AND hd.hd_income_band_sk > 10
      AND ss.ss_net_paid >= 100
)
SELECT
    order_number,
    sold_date_sk,
    item_id,
    item_size,
    customer_gender,
    income_band,
    net_paid,
    profit_status,
    has_returned,
    return_count
FROM combined
ORDER BY net_paid DESC
LIMIT 100
