WITH brand_avg_return AS (
    SELECT i.i_brand AS brand,
           AVG(sr.sr_return_amt) AS avg_brand_return_amt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20
    GROUP BY i.i_brand
)
SELECT
    sr.sr_ticket_number,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    sr.sr_return_amt,
    COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY sr.sr_return_amt DESC) AS brand_return_rank,
    CASE
        WHEN sr.sr_return_amt > (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = sr.sr_item_sk
        ) THEN 'High'
        ELSE 'Normal'
    END AS return_level,
    ib.avg_brand_return_amt
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN brand_avg_return ib ON i.i_brand = ib.brand
WHERE i.i_current_price > 50
  AND cd.cd_marital_status = 'M'
  AND (hd.hd_buy_potential = '>10000' OR hd.hd_buy_potential IS NULL)
  AND sr.sr_return_amt > 100
ORDER BY i.i_brand, brand_return_rank
LIMIT 100
