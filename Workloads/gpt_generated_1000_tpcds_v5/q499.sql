WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cs.cs_ext_tax > 20.00
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    w.web_name,
    ss.ss_quantity,
    sr.sr_return_quantity,
    sales_agg.total_net_paid,
    sales_agg.total_tax,
    RANK() OVER (PARTITION BY d.d_year ORDER BY sales_agg.total_net_paid DESC) AS yearly_sales_rank,
    CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS return_status
FROM sales_agg
JOIN date_dim d ON sales_agg.cs_sold_date_sk = d.d_date_sk
JOIN item i ON sales_agg.cs_item_sk = i.i_item_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_site w
    ON w.web_open_date_sk = d.d_date_sk
WHERE i.i_class = 'furniture'
  AND w.web_tax_percentage = 0.08
  AND t.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_net_loss > 0
          AND sr2.sr_returned_date_sk = d.d_date_sk
    )
ORDER BY yearly_sales_rank, d.d_date
LIMIT 100
