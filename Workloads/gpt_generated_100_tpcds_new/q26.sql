WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cr.cr_return_amount,
        cr.cr_return_tax,
        i1.i_item_sk,
        i1.i_brand,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_store_sk
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i1
        ON cr.cr_item_sk = i1.i_item_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i1.i_item_sk
)
SELECT
    base.cc_name,
    i2.i_brand AS item_brand_return,
    SUM(base.ss_net_profit) AS total_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT base.ss_ticket_number) AS distinct_sales,
    AVG(cr2.cr_return_tax) AS avg_catalog_return_tax
FROM base
JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = base.i_item_sk
JOIN tpcds.store_sales ss2
    ON sr.sr_ticket_number = ss2.ss_ticket_number
JOIN tpcds.item i2
    ON sr.sr_item_sk = i2.i_item_sk
JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = base.i_item_sk
JOIN tpcds.catalog_returns cr2
    ON cr2.cr_call_center_sk = base.cc_call_center_sk
JOIN tpcds.item i3
    ON cr2.cr_item_sk = i3.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_ticket_number = base.ss_ticket_number
      AND sr2.sr_return_quantity > 10
)
GROUP BY
    base.cc_name,
    i2.i_brand
ORDER BY total_profit DESC
LIMIT 100
