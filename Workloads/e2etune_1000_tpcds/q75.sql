WITH sales_returns AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_ship_date_sk AS ship_date_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_quantity,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        ws.web_tax_percentage
    FROM catalog_sales cs
    JOIN web_returns wr
        ON cs.cs_item_sk = wr.wr_item_sk
        AND cs.cs_sold_date_sk = wr.wr_returned_date_sk
    JOIN web_site ws
        ON cs.cs_ship_date_sk = ws.web_open_date_sk
    WHERE cs.cs_ext_discount_amt > 1000
      AND cs.cs_sales_price BETWEEN 20 AND 150
),
aggregated AS (
    SELECT
        ib.ib_income_band_sk,
        sr.sold_date_sk,
        SUM(sr.cs_net_profit) AS total_profit,
        SUM(sr.wr_net_loss) AS total_loss,
        SUM(sr.wr_net_loss) / NULLIF(SUM(sr.cs_net_profit), 0) AS loss_ratio,
        AVG(sr.web_tax_percentage) AS avg_site_tax
    FROM sales_returns sr
    JOIN income_band ib
        ON sr.cs_net_paid BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY ib.ib_income_band_sk, sr.sold_date_sk
    HAVING SUM(sr.cs_net_profit) > 0
)
SELECT
    a.ib_income_band_sk,
    a.sold_date_sk,
    a.total_profit,
    a.total_loss,
    a.loss_ratio,
    a.avg_site_tax,
    RANK() OVER (PARTITION BY a.sold_date_sk ORDER BY a.total_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.loss_ratio DESC
LIMIT 100
