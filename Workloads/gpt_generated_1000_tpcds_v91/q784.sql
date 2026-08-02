WITH high_income_customers AS (
    SELECT DISTINCT cs.cs_bill_cdemo_sk AS cd_demo_sk
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 150000
)
SELECT
    i_item_id,
    sale_date_sk,
    net_paid,
    profit_flag,
    cumulative_net_paid,
    return_cnt,
    sales_channel
FROM (
    SELECT
        i.i_item_id,
        cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_net_paid AS net_paid,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        SUM(cs.cs_net_paid) OVER (
            PARTITION BY cs.cs_item_sk
            ORDER BY cs.cs_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_net_paid,
        (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_order_number = cs.cs_order_number) AS return_cnt,
        CAST('Catalog' AS varchar) AS sales_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN high_income_customers hic ON cs.cs_bill_cdemo_sk = hic.cd_demo_sk
    WHERE i.i_current_price > 100
    UNION
    SELECT
        i.i_item_id,
        ws.ws_sold_date_sk AS sale_date_sk,
        ws.ws_net_paid AS net_paid,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        SUM(ws.ws_net_paid) OVER (
            PARTITION BY ws.ws_item_sk
            ORDER BY ws.ws_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_net_paid,
        (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_order_number = ws.ws_order_number) AS return_cnt,
        CAST('Web' AS varchar) AS sales_channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN high_income_customers hic ON ws.ws_bill_cdemo_sk = hic.cd_demo_sk
    WHERE ws.ws_ext_tax > 20
) combined
ORDER BY net_paid DESC, sale_date_sk ASC
LIMIT 100
